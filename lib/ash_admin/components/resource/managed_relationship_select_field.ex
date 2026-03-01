defmodule AshAdmin.Components.Resource.ManagedRelationshipSelectField do
  @moduledoc """
  A LiveComponent for rendering a managed relationship field as a select/typeahead
  instead of nested form inputs. Used when the destination resource has a `label_field` configured.
  """

  use Phoenix.LiveComponent

  import AshAdmin.CoreComponents
  import Ash.Expr

  require Ash.Query

  def mount(socket) do
    {:ok,
     assign(socket,
       suggestions: [],
       search_term: "",
       highlighted_index: -1
     )}
  end

  def update(assigns, socket) do
    destination = assigns.relationship.destination
    pk_field = Ash.Resource.Info.primary_key(destination) |> List.first()
    label_field = AshAdmin.Resource.label_field(destination)
    max_items = AshAdmin.Resource.relationship_select_max_items(destination)

    {:ok,
     assign(socket, assigns)
     |> assign(
       pk_field: pk_field,
       label_field: label_field,
       max_items: max_items,
       destination: destination
     )}
  end

  def render(assigns) do
    all_options = load_all_options(assigns)
    selected_ids = MapSet.new(assigns.selected_ids, &to_string/1)
    available_options = Enum.reject(all_options, fn {_label, id} -> to_string(id) in selected_ids end)
    field_type = if length(all_options) <= assigns.max_items, do: :select, else: :typeahead

    assigns =
      assign(assigns,
        available_options: available_options,
        field_type: field_type,
        search_term: assigns.search_term
      )

    ~H"""
    <div class="mt-1">
      <.input
        :if={@field_type == :select && @available_options != []}
        type="select"
        options={@available_options}
        prompt={"Add #{relationship_label(@relationship)}..."}
        id={@id <> "-select"}
        name={"_#{@id}_add"}
        value=""
        phx-change="select_item"
        phx-target={@myself}
      />
      <div
        :if={@field_type == :typeahead}
        id={@id}
        class="autocomplete-combobox"
        role="combobox"
        aria-haspopup="listbox"
        aria-owns={"#{@id}-listbox"}
        aria-expanded={if @suggestions != [], do: "true", else: "false"}
      >
        <div class="relative">
          <input
            type="text"
            id={"#{@id}-input"}
            value={@search_term}
            name={"_#{@id}_suggest"}
            class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 border-zinc-300 focus:border-zinc-400 pr-9"
            phx-keyup="suggest"
            phx-debounce="300"
            phx-target={@myself}
            placeholder={"Search #{relationship_label(@relationship)}..."}
            autocomplete="off"
          />
        </div>
        <ul
          :if={Enum.count(@suggestions) > 0}
          id={"#{@id}-listbox"}
          role="listbox"
          class="absolute z-10 mt-1 bg-white shadow-lg rounded-md px-2 py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm"
        >
          <%= for {{suggestion_name, suggestion_id}, index} <- Enum.with_index(@suggestions) do %>
            <li
              id={"#{@id}-option-#{index}"}
              class={[
                "cursor-pointer select-none relative py-2 px-2 w-full truncate",
                if(index == @highlighted_index,
                  do: "text-white bg-indigo-500",
                  else: "text-gray-900 hover:bg-indigo-400 hover:text-gray-100"
                )
              ]}
              role="option"
              tabindex="0"
              phx-click="select_suggestion"
              phx-value-id={suggestion_id}
              phx-target={@myself}
            >
              <% escaped_term = Regex.escape(@search_term) %>
              <% suggestion_name =
                String.replace(to_string(suggestion_name), ~r/(#{escaped_term})/i, "<b>\\0</b>") %>
              {Phoenix.HTML.raw(suggestion_name)}
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("select_item", params, socket) do
    id = params["_#{socket.assigns.id}_add"] || ""

    if id != "" do
      send_update(socket.assigns.form_component_module,
        id: socket.assigns.form_component_id,
        add_related: %{
          path: socket.assigns.form_path,
          pk_field: to_string(socket.assigns.pk_field),
          id: id
        }
      )
    end

    {:noreply, socket}
  end

  def handle_event("suggest", %{"value" => search_term, "key" => key}, socket) do
    cond do
      key == "ArrowDown" and Enum.any?(socket.assigns.suggestions) ->
        new_index =
          min(socket.assigns.highlighted_index + 1, Enum.count(socket.assigns.suggestions) - 1)

        {:noreply, assign(socket, highlighted_index: new_index)}

      key == "ArrowUp" and Enum.any?(socket.assigns.suggestions) ->
        new_index = max(socket.assigns.highlighted_index - 1, 0)
        {:noreply, assign(socket, highlighted_index: new_index)}

      key == "Enter" and socket.assigns.highlighted_index >= 0 ->
        {_name, id} = Enum.at(socket.assigns.suggestions, socket.assigns.highlighted_index)

        send_update(socket.assigns.form_component_module,
          id: socket.assigns.form_component_id,
          add_related: %{
            path: socket.assigns.form_path,
            pk_field: to_string(socket.assigns.pk_field),
            id: to_string(id)
          }
        )

        {:noreply,
         assign(socket, suggestions: [], search_term: "", highlighted_index: -1)}

      key == "Escape" ->
        {:noreply,
         assign(socket, suggestions: [], search_term: "", highlighted_index: -1)}

      true ->
        suggestions = fetch_suggestions(socket.assigns, search_term)
        {:noreply, assign(socket, suggestions: suggestions, search_term: search_term, highlighted_index: -1)}
    end
  end

  def handle_event("select_suggestion", %{"id" => id}, socket) do
    send_update(socket.assigns.form_component_module,
      id: socket.assigns.form_component_id,
      add_related: %{
        path: socket.assigns.form_path,
        pk_field: to_string(socket.assigns.pk_field),
        id: id
      }
    )

    {:noreply, assign(socket, suggestions: [], search_term: "", highlighted_index: -1)}
  end

  defp relationship_label(relationship) do
    relationship.name |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp load_all_options(assigns) do
    resource = assigns.destination
    label_field = assigns.label_field
    limit = assigns.max_items + 1

    resource
    |> Ash.Query.new()
    |> Ash.Query.load([label_field])
    |> Ash.Query.limit(limit)
    |> Ash.read!(
      actor: assigns[:actor],
      authorize?: assigns[:authorizing],
      tenant: assigns[:tenant]
    )
    |> then(fn
      %Ash.Page.Offset{results: results} -> results
      results -> results
    end)
    |> Enum.map(&{to_string(Map.get(&1, label_field)), to_string(&1.id)})
  end

  defp fetch_suggestions(_assigns, "") do
    []
  end

  defp fetch_suggestions(assigns, search_term) do
    assigns.destination
    |> Ash.Query.new()
    |> Ash.Query.load([assigns.label_field])
    |> Ash.Query.filter(
      contains(
        ^ref(assigns.label_field),
        ^%Ash.CiString{string: search_term}
      )
    )
    |> Ash.Query.limit(assigns.max_items)
    |> Ash.read!(
      actor: assigns[:actor],
      authorize?: assigns[:authorizing],
      tenant: assigns[:tenant]
    )
    |> then(fn
      %Ash.Page.Offset{results: results} -> results
      results -> results
    end)
    |> Enum.map(&{to_string(Map.get(&1, assigns.label_field)), to_string(&1.id)})
    |> Enum.reject(fn {_label, id} -> to_string(id) in Enum.map(assigns.selected_ids, &to_string/1) end)
  end
end
