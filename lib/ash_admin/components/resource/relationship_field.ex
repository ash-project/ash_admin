# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
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
  require Logger

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
    max_items = AshAdmin.Resource.relationship_select_max_items(assigns.resource)

    current_label =
      get_current_label(assigns.resource, assigns.value, label_field, ash_opts(assigns))

    {select_options, errors} =
      case select_options(assigns.resource, label_field, max_items, ash_opts(assigns)) do
        {:ok, options} -> {options, []}
        {:error, error} -> {[], [error_message(error, assigns.resource, "load")]}
      end

    {:ok,
     assign(socket, assigns)
     |> assign(
       pk_field: pk_field,
       label_field: label_field,
       current_label: current_label,
       selected_id: assigns.value,
       max_items: max_items,
       limited_select_options: select_options,
       field_type: field_type(select_options, max_items, errors),
       errors: errors
     )}
  end

  defp get_current_label(_, nil, _, _) do
    ""
  end

  defp get_current_label(resource, value, label_field, opts) do
    with {:ok, record} <- Ash.get(resource, value, opts),
         {:ok, record} <- Ash.load(record, label_field, opts) do
      label_string(Map.get(record, label_field))
    else
      _ ->
        ""
    end
  end

  defp ash_opts(assigns) do
    [actor: assigns[:actor], authorize?: assigns[:authorizing], tenant: assigns[:tenant]]
  end

  # Labels are rendered into HTML attributes and highlighted with a regex, so
  # they must be plain strings. A label the actor may not see comes back as
  # `%Ash.ForbiddenField{}`, which has no `String.Chars` implementation.
  @doc false
  def label_string(nil), do: ""
  def label_string(value) when is_binary(value), do: value
  def label_string(%Ash.CiString{} = value), do: to_string(value)
  def label_string(%Ash.ForbiddenField{}), do: "(forbidden)"
  def label_string(%Ash.NotLoaded{}), do: ""

  def label_string(value) do
    if String.Chars.impl_for(value) do
      to_string(value)
    else
      inspect(value)
    end
  end

  defp error_message(error, resource, verb) do
    Logger.warning(
      "Error while trying to #{verb} #{inspect(resource)} in relationship field\n: #{Exception.format(:error, error)}"
    )

    detail =
      case error do
        %Ash.Error.Forbidden{} ->
          "forbidden"

        %{errors: [first | _]} when is_exception(first) ->
          first |> Exception.message() |> String.split("\n", parts: 2) |> hd()

        error when is_exception(error) ->
          error |> Exception.message() |> String.split("\n", parts: 2) |> hd()

        other ->
          inspect(other)
      end

    "Could not #{verb} #{form_control_label(resource)}: #{detail}"
  end

  @spec render(atom() | %{:resource => atom() | Ash.Query.t(), optional(any()) => any()}) ::
          Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    assigns =
      assign(assigns,
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
            <.icon
              name="hero-x-circle"
              class="h-5 w-5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
            />
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
          class="absolute z-10 mt-1 bg-white dark:bg-slate-800 shadow-lg rounded-md px-2 py-1 text-base ring-1 ring-slate-200 dark:ring-slate-700 overflow-auto focus:outline-none sm:text-sm"
          phx-update="replace"
        >
          <%= for {{suggestion_name, suggestion_id}, index} <- Enum.with_index(@suggestions) do %>
            <li
              id={"#{@id}-option-#{index}"}
              data-target-id={"#{@id}-hidden"}
              class={[
                "cursor-pointer select-none relative py-2 px-2 w-full truncate",
                if(index == @highlighted_index,
                  do: "text-white bg-slate-700 dark:bg-slate-500",
                  else:
                    "text-slate-900 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-700"
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
                suggestion_name
                |> to_string()
                |> Phoenix.HTML.html_escape()
                |> Phoenix.HTML.safe_to_string()
                |> String.replace(~r/(#{escaped_term})/i, "<b>\\0</b>") %>
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
      key == "ArrowDown" and Enum.any?(socket.assigns.suggestions) ->
        new_index =
          min(socket.assigns.highlighted_index + 1, Enum.count(socket.assigns.suggestions) - 1)

        {_new_suggestion_name, new_suggestion_id} = Enum.at(socket.assigns.suggestions, new_index)

        {:noreply,
         assign(socket,
           highlighted_index: new_index,
           current_suggestion_id: new_suggestion_id
         )}

      key == "ArrowUp" and Enum.any?(socket.assigns.suggestions) ->
        new_index =
          max(socket.assigns.highlighted_index - 1, 0)

        {_new_suggestion_name, new_suggestion_id} =
          Enum.at(socket.assigns.suggestions, new_index)

        {:noreply,
         assign(socket, highlighted_index: new_index, current_suggestion_id: new_suggestion_id)}

      key == "Enter" ->
        case Enum.at(socket.assigns.suggestions, max(socket.assigns.highlighted_index, 0)) do
          nil ->
            {:noreply, socket}

          {suggestion_name, suggestion_id} ->
            {:noreply,
             assign(socket,
               search_term: suggestion_name,
               current_label: suggestion_name,
               selected_id: suggestion_id,
               suggestions: [],
               highlighted_index: -1
             )}
        end

      key == "Escape" ->
        field_name = Map.get(socket.assigns.attribute, :name)
        original_value = Map.get(socket.assigns.form.data, field_name)

        original_label =
          get_current_label(
            socket.assigns.resource,
            original_value,
            socket.assigns.label_field,
            ash_opts(socket.assigns)
          )

        {:noreply,
         assign(socket,
           selected_id: original_value,
           current_label: original_label,
           suggestions: [],
           highlighted_index: -1
         )}

      true ->
        case fetch_suggestions(socket.assigns, search_term) do
          {:ok, suggestions} ->
            {:noreply,
             assign(socket,
               suggestions: suggestions,
               search_term: search_term,
               highlighted_index: -1,
               errors: []
             )}

          {:error, error} ->
            {:noreply,
             assign(socket,
               suggestions: [],
               search_term: search_term,
               highlighted_index: -1,
               errors: [error_message(error, socket.assigns.resource, "search")]
             )}
        end
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

  # When the option list could not be loaded, fall back to the typeahead so the
  # form still renders and the error is shown next to the field.
  defp field_type(_options, _max_items, [_ | _]), do: :typeahead
  defp field_type(options, max_items, []) when length(options) <= max_items, do: :select
  defp field_type(_options, _max_items, []), do: :typeahead

  defp select_options(resource, label_field, max_items, opts) do
    pk_field = resource |> Ash.Resource.Info.primary_key() |> List.first()

    resource
    |> Ash.Query.new()
    |> Ash.Query.load([pk_field, label_field])
    |> Ash.Query.limit(max_items + 1)
    |> Ash.read(opts)
    |> case do
      {:ok, %Ash.Page.Offset{results: results}} ->
        {:ok, to_options(results, pk_field, label_field)}

      {:ok, %Ash.Page.Keyset{results: results}} ->
        {:ok, to_options(results, pk_field, label_field)}

      {:ok, results} ->
        {:ok, to_options(results, pk_field, label_field)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp fetch_suggestions(_assigns, "") do
    {:ok, []}
  end

  defp fetch_suggestions(assigns, search_term) do
    assigns.resource
    |> Ash.Query.new()
    |> Ash.Query.load([
      assigns.pk_field,
      assigns.label_field
    ])
    |> Ash.Query.filter(^search_filter(assigns, search_term))
    |> Ash.Query.sort(ash_admin_position_sort: {%{search_term: search_term}, :asc})
    |> Ash.Query.limit(assigns.max_items)
    |> Ash.read(ash_opts(assigns))
    |> case do
      {:ok, results} -> {:ok, to_options(results, assigns.pk_field, assigns.label_field)}
      {:error, error} -> {:error, error}
    end
  end

  # Match on the label, and also on the primary key when the resource has a
  # single-field primary key and the typed text is a valid value for it (e.g. a
  # pasted UUID), since the label is the only searchable field otherwise.
  defp search_filter(assigns, search_term) do
    label_match =
      expr(contains(^ref(assigns.label_field), ^%Ash.CiString{string: search_term}))

    case cast_primary_key(assigns.resource, search_term) do
      {:ok, pk_field, pk_value} ->
        expr(^label_match or ^ref(pk_field) == ^pk_value)

      :error ->
        label_match
    end
  end

  defp cast_primary_key(resource, search_term) do
    with [pk_field] <- Ash.Resource.Info.primary_key(resource),
         %{type: type, constraints: constraints} <-
           Ash.Resource.Info.attribute(resource, pk_field),
         {:ok, value} when not is_nil(value) <-
           Ash.Type.cast_input(type, search_term, constraints) do
      {:ok, pk_field, value}
    else
      _ -> :error
    end
  end

  defp to_options(results, pk_field, label_field) do
    Enum.map(results, &{label_string(Map.get(&1, label_field)), Map.get(&1, pk_field)})
  end
end
