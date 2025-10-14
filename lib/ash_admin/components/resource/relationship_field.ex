# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.RelationshipField do
  @moduledoc """
  This module defines a LiveComponent for rendering a relationship field in an AshAdmin resource form.
  It handles the logic for displaying a select dropdown or a typeahead input field, fetching and
  displaying suggestions, and updating the selected value.
  """

  use Phoenix.LiveComponent

  import AshAdmin.CoreComponents
  import Ash.Expr

  require Ash.Query

  alias Phoenix.LiveView.JS

  def form_control_label(resource) do
    Ash.Resource.Info.short_name(resource) |> to_string |> String.capitalize()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       suggestions: [],
       search_term: "",
       selected_id: nil,
       current_suggestion_id: nil,
       highlighted_index: -1,
       errors: []
     )}
  end

  def update(assigns, socket) do
    pk_field = Ash.Resource.Info.primary_key(assigns.resource) |> List.first()
    label_field = AshAdmin.Resource.label_field(assigns.resource)
    current_label = get_current_label(assigns.resource, assigns.value, label_field)

    {:ok,
     assign(socket, assigns)
     |> assign(
       pk_field: pk_field,
       label_field: label_field,
       current_label: current_label,
       selected_id: assigns.value,
       max_items: AshAdmin.Resource.relationship_select_max_items(assigns.resource)
     )}
  end

  defp get_current_label(_, nil, _) do
    ""
  end

  defp get_current_label(resource, value, label_field) do
    case resource |> Ash.get(value) do
      {:ok, record} ->
        record
        |> Ash.load!(label_field)
        |> Map.get(label_field)

      _ ->
        ""
    end
  end

  @spec render(atom() | %{:resource => atom() | Ash.Query.t(), optional(any()) => any()}) ::
          Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    select_options = select_options!(assigns)

    assigns =
      assign(assigns,
        limited_select_options: select_options,
        field_type: field_type(select_options, assigns.max_items),
        label: form_control_label(assigns.resource),
        search_term: assigns.search_term
      )

    ~H"""
    <div class="mt-1">
      <.input
        :if={@field_type == :select}
        type="select"
        options={@limited_select_options}
        prompt={"Select #{@label}"}
        id={@id}
        name={@form.name <> "[#{@attribute.name}]"}
        value={@value}
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
        <!-- Visible Input Field -->
        <div class="relative">
          <input
            type="text"
            id={"#{@id}-input"}
            data-target-id={"#{@id}-hidden"}
            value={@current_label}
            name={"#{@id}-suggest"}
            class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 border-zinc-300 focus:border-zinc-400 pr-9"
            phx-keyup="suggest"
            phx-debounce="300"
            phx-target={@myself}
            phx-hook="Typeahead"
            aria-autocomplete="list"
            aria-controls={"#{@id}-listbox"}
            aria-activedescendant={
              if @highlighted_index >= 0, do: "#{@id}-option-#{@highlighted_index}", else: ""
            }
            autocomplete="off"
          />
          <button
            type="button"
            class="absolute inset-y-0 right-0 pr-2 flex items-center"
            data-target-id={"#{@id}-input"}
            phx-click="clear"
            phx-target={@myself}
          >
            <.icon name="hero-x-circle" class="h-5 w-5 text-gray-400 hover:text-gray-600" />
          </button>
        </div>
        <!-- Hidden Input Field -->
        <input
          type="hidden"
          id={"#{@id}-hidden"}
          name={@form.name <> "[#{@attribute.name}]"}
          value={@selected_id || ""}
        />
        <!-- Dropdown List -->
        <ul
          :if={Enum.count(@suggestions) > 0}
          id={"#{@id}-listbox"}
          role="listbox"
          class="absolute z-10 mt-1 bg-white shadow-lg rounded-md px-2 py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm"
          phx-update="replace"
        >
          <%= for {{suggestion_name, suggestion_id}, index} <- Enum.with_index(@suggestions) do %>
            <li
              id={"#{@id}-option-#{index}"}
              data-target-id={"#{@id}-hidden"}
              class={[
                "cursor-pointer select-none relative py-2 px-2 w-full truncate",
                if(index == @highlighted_index,
                  do: "text-white bg-indigo-500",
                  else: "text-gray-900 hover:bg-indigo-400 hover:text-gray-100"
                )
              ]}
              role="option"
              tabindex="0"
              phx-hook="Typeahead"
              phx-click={JS.push("select")}
              phx-value-id={suggestion_id}
              phx-value-name={suggestion_name}
              phx-target={@myself}
            >
              <% escaped_term = Regex.escape(@search_term) %>
              <% suggestion_name =
                String.replace(suggestion_name, ~r/(#{escaped_term})/i, "<b>\\0</b>") %>
              {Phoenix.HTML.raw(suggestion_name)}
            </li>
          <% end %>
        </ul>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Handle user input and fetch suggestions
  def handle_event(
        "suggest",
        %{"value" => search_term, "key" => key},
        socket
      ) do
    cond do
      key == "ArrowDown" and length(socket.assigns.suggestions) > 0 ->
        new_index =
          min(socket.assigns.highlighted_index + 1, length(socket.assigns.suggestions) - 1)

        {_new_suggestion_name, new_suggestion_id} = Enum.at(socket.assigns.suggestions, new_index)

        {:noreply,
         assign(socket,
           highlighted_index: new_index,
           current_suggestion_id: new_suggestion_id
         )}

      key == "ArrowUp" and length(socket.assigns.suggestions) > 0 ->
        new_index =
          max(socket.assigns.highlighted_index - 1, 0)

        {_new_suggestion_name, new_suggestion_id} =
          Enum.at(socket.assigns.suggestions, new_index)

        {:noreply,
         assign(socket, highlighted_index: new_index, current_suggestion_id: new_suggestion_id)}

      key == "Enter" ->
        if Enum.empty?(socket.assigns.suggestions) do
          {:noreply, socket.assigns}
        end

        {suggestion_name, suggestion_id} =
          Enum.at(socket.assigns.suggestions, socket.assigns.highlighted_index)

        {:noreply,
         assign(socket,
           search_term: suggestion_name,
           current_label: suggestion_name,
           selected_id: suggestion_id,
           suggestions: [],
           highlighted_index: -1
         )}

      key == "Escape" ->
        field_name = Map.get(socket.assigns.attribute, :name)
        original_value = Map.get(socket.assigns.form.data, field_name)

        original_label =
          get_current_label(
            socket.assigns.resource,
            original_value,
            socket.assigns.label_field
          )

        {:noreply,
         assign(socket,
           selected_id: original_value,
           current_label: original_label,
           suggestions: [],
           highlighted_index: -1
         )}

      true ->
        suggestions = fetch_suggestions(socket.assigns, search_term)

        {:noreply,
         assign(socket, suggestions: suggestions, search_term: search_term, highlighted_index: -1)}
    end
  end

  # Handle suggestion selection via click
  def handle_event("select", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     assign(socket,
       search_term: name,
       current_label: name,
       selected_id: id,
       suggestions: [],
       highlighted_index: -1
     )}
  end

  def handle_event("clear", _, socket) do
    {:noreply, assign(socket, search_term: "", current_label: "")}
  end

  defp field_type(options, max_items) when length(options) <= max_items, do: :select
  defp field_type(_options, _max_items), do: :typeahead

  defp select_options!(assigns) do
    resource = assigns.resource

    limit = assigns.max_items + 1
    label_field = AshAdmin.Resource.label_field(resource)
    pk_field = Ash.Resource.Info.primary_key(resource)

    resource
    |> Ash.Query.new()
    |> Ash.Query.load([pk_field, label_field])
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
    |> Enum.map(&{Map.get(&1, label_field), &1.id})
  end

  defp fetch_suggestions(_assigns, "") do
    []
  end

  defp fetch_suggestions(assigns, search_term) do
    assigns.resource
    |> Ash.Query.new()
    |> Ash.Query.load([
      assigns.pk_field,
      assigns.label_field
    ])
    |> Ash.Query.filter(
      contains(
        ^ref(assigns.label_field),
        ^%Ash.CiString{string: search_term}
      )
    )
    |> Ash.Query.sort(ash_admin_position_sort: {%{search_term: search_term}, :asc})
    |> Ash.Query.limit(assigns.max_items)
    |> Ash.read!()
    |> Enum.map(&{Map.get(&1, assigns.label_field), &1.id})
  end
end
