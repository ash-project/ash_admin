# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.DataTable do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.Helpers
  alias AshAdmin.Components.Resource.CinderTable

  attr :resource, :atom
  attr :domain, :atom
  attr :action, :any
  attr :authorizing, :boolean
  attr :actor, :any
  attr :url_path, :any
  attr :params, :any
  attr :table, :any, required: true
  attr :tables, :any, required: true
  attr :prefix, :any, required: true
  attr :tenant, :any, required: true
  attr :polymorphic_actions, :any, required: true

  def render(assigns) do
    ~H"""
    <div>
      <div class="sm:mt-0 bg-gray-300 min-h-screen">
        <div
          :if={@action.arguments != []}
          class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:pt-10 mb-10"
        >
          <div class="md:mt-0 md:col-span-2">
            <div class="shadow-lg overflow-hidden pt-2 sm:rounded-md bg-white">
              <div class="px-4 sm:p-6">
                <.form
                  :let={form}
                  :if={@query}
                  as={:query}
                  for={@query}
                  phx-change="validate"
                  phx-submit="save"
                  phx-target={@myself}
                >
                  <div :if={form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
                    <ul>
                      <li :for={{field, message} <- all_errors(form)}>
                        <span :if={field}>
                          {field}:
                        </span>
                        <span>
                          {message}
                        </span>
                      </li>
                    </ul>
                  </div>
                  {AshAdmin.Components.Resource.Form.render_attributes(
                    assigns,
                    @resource,
                    @action,
                    form
                  )}
                  <div class="px-4 py-3 text-right sm:px-6">
                    <button
                      type="submit"
                      class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Run Query
                    </button>
                  </div>
                </.form>
              </div>
            </div>
          </div>
        </div>

        <div :if={@tables != []} class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:pt-10 mb-10">
          <div class="md:mt-0 md:col-span-2">
            <div class="px-4 sm:p-6">
              <AshAdmin.Components.Resource.SelectTable.table
                resource={@resource}
                action={@action}
                on_change="change_table"
                target={@myself}
                table={@table}
                tables={@tables}
                polymorphic_actions={@polymorphic_actions}
              />
            </div>
          </div>
        </div>

        <div :if={@action.arguments == [] || @params["args"]} class="h-full overflow-auto md:mx-4">
          <div class="shadow-lg overflow-auto sm:rounded-md bg-white">
            <div :if={match?({:error, _}, @data) && @action.arguments == []}>
              <ul>
                <%= for {path, error} <- AshPhoenix.Form.errors(@query, for_path: :all) do %>
                  <%= for {field, message} <- error do %>
                    <li>{Enum.join(path ++ [field], ".")}: {message}</li>
                  <% end %>
                <% end %>
              </ul>
            </div>
            <div class="px-2">
              <div :if={@thousand_records_warning && !@action.get? && !@action.pagination}>
                Only showing up to 1000 rows. To show more, enable
                <a href="https://hexdocs.pm/ash/pagination.html">pagination</a>
                for the action in question.
              </div>
              <div :if={can_render_table?(assigns)} class="mx-5 mt-5 mb-2">
                <button
                  type="button"
                  phx-click="toggle_filters"
                  phx-target={@myself}
                  class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors duration-150"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
                    />
                  </svg>
                  {if @show_filters, do: "Hide Filters", else: "Show Filters"}
                </button>
              </div>
              <CinderTable.table
                :if={can_render_table?(assigns)}
                table={@table}
                query={build_cinder_query(assigns)}
                resource={@resource}
                domain={@domain}
                attributes={AshAdmin.Resource.table_columns(@resource)}
                format_fields={AshAdmin.Resource.format_fields(@resource)}
                show_sensitive_fields={AshAdmin.Resource.show_sensitive_fields(@resource)}
                prefix={@prefix}
                actor={@actor}
                tenant={@tenant}
                page_size={get_page_size(assigns)}
                authorizing={@authorizing}
                show_filters={@show_filters}
                theme={AshAdmin.Themes.AshAdminTheme}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:initialized, fn -> false end)
     |> assign_new(:default, fn -> nil end)
     |> assign_new(:show_filters, fn -> false end)
     |> assign_new(:thousand_records_warning, fn -> false end)}
  end

  def update(assigns, socket) do
    if assigns[:initialized] do
      {:ok, socket}
    else
      socket = assign(socket, assigns)
      params = socket.assigns[:params] || %{}
      arguments = params["args"]

      query =
        socket.assigns[:resource]
        |> AshPhoenix.Form.for_read(socket.assigns.action.name,
          as: "query",
          domain: socket.assigns[:domain],
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant],
          authorize?: socket.assigns[:authorizing],
          prepare_source: &load_fields/1
        )

      {query, run_now?} =
        if arguments do
          {Map.put(AshPhoenix.Form.validate(query, arguments), :submitted_once?, true), true}
        else
          {query, socket.assigns.action.arguments == []}
        end

      socket = assign(socket, :query, query)

      # With Cinder, we don't manually fetch data - it handles querying and pagination
      # We just validate the form if there are arguments
      socket =
        if run_now? && socket.assigns.action.arguments != [] do
          if socket.assigns[:tables] not in [[], nil] && !socket.assigns[:table] do
            assign(socket, :data, {:ok, []})
          else
            # Validate that the arguments are correct, but don't execute the query
            # Cinder will handle execution
            assign(socket, :data, {:ok, :cinder_will_query})
          end
        else
          assign(socket, :data, :loading)
        end

      {:ok,
       socket
       |> assign(:initialized, true)}
    end
  end

  defp load_fields(query) do
    query
    |> Ash.Query.select([])
    |> Ash.Query.load(AshAdmin.Resource.table_columns(query.resource))
  end

  defp all_errors(form) do
    form
    |> AshPhoenix.Form.errors(for_path: :all)
    |> Enum.flat_map(fn {path, errors} ->
      Enum.map(errors, fn {field, message} ->
        path = List.wrap(path)

        case Enum.reject(path ++ List.wrap(field), &is_nil/1) do
          [] ->
            {nil, message}

          items ->
            {Enum.join(items, "."), message}
        end
      end)
    end)
  end

  # Pagination is handled by Cinder, no need for these event handlers

  def handle_event("validate", %{"query" => query}, socket) do
    query = AshPhoenix.Form.validate(socket.assigns.query, query)

    {:noreply, assign(socket, query: query)}
  end

  def handle_event("save", %{"query" => query_params}, socket) do
    {:noreply,
     push_navigate(
       socket,
       to: self_path(socket.assigns.url_path, socket.assigns.params, %{"args" => query_params})
     )}
  end

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  def handle_event("change_table", %{"table" => %{"table" => table}}, socket) do
    {:noreply,
     push_navigate(socket,
       to: self_path(socket.assigns.url_path, socket.assigns.params, %{"table" => table})
     )}
  end

  def handle_event("add_form", %{"path" => path} = params, socket) do
    type =
      case params["type"] do
        "lookup" -> :read
        _ -> :create
      end

    query = AshPhoenix.Form.add_form(socket.assigns.query, path, type: type)

    {:noreply,
     socket
     |> assign(:query, query)}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    query = AshPhoenix.Form.remove_form(socket.assigns.query, path)

    {:noreply,
     socket
     |> assign(:query, query)}
  end

  def handle_event("remove_value", %{"path" => path, "field" => field, "index" => index}, socket) do
    query =
      AshPhoenix.Form.update_form(
        socket.assigns.query,
        path,
        &remove_value(&1, field, index)
      )

    {:noreply,
     socket
     |> assign(:query, query)}
  end

  def handle_event("append_value", %{"path" => path, "field" => field}, socket) do
    list =
      AshPhoenix.Form.get_form(socket.assigns.query, path)
      |> AshPhoenix.Form.value(String.to_existing_atom(field))
      |> Kernel.||([])
      |> indexed_list()
      |> append_to_and_map(nil)

    params =
      put_in_creating(
        socket.assigns.query.params || %{},
        Enum.map(
          AshPhoenix.Form.parse_path!(socket.assigns.query, path) ++ [field],
          &to_string/1
        ),
        list
      )

    query = AshPhoenix.Form.validate(socket.assigns.query, params)

    {:noreply,
     socket
     |> assign(:query, query)}
  end

  defp indexed_list(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
    |> Enum.sort()
    |> Enum.map(&map[to_string(&1)])
  rescue
    _ ->
      List.wrap(map)
  end

  defp indexed_list(other), do: List.wrap(other)

  defp append_to_and_map(list, value) do
    list
    |> Enum.concat([value])
    |> Enum.with_index()
    |> Map.new(fn {v, i} ->
      {"#{i}", v}
    end)
  end

  defp put_in_creating(map, [key], value) do
    Map.put(map || %{}, key, value)
  end

  defp put_in_creating(list, [key | rest], value) when is_list(list) do
    List.update_at(list, String.to_integer(key), &put_in_creating(&1, rest, value))
  end

  defp put_in_creating(map, [key | rest], value) do
    map
    |> Kernel.||(%{})
    |> Map.put_new(key, %{})
    |> Map.update!(key, &put_in_creating(&1, rest, value))
  end

  defp remove_value(form, field, index) do
    current_value =
      form
      |> AshPhoenix.Form.value(String.to_existing_atom(field))
      |> case do
        map when is_map(map) ->
          map

        list ->
          list
          |> List.wrap()
          |> Enum.with_index()
          |> Map.new(fn {value, index} ->
            {to_string(index), value}
          end)
      end

    new_value = Map.delete(current_value, index)

    new_value =
      if new_value == %{} do
        nil
      else
        new_value
      end

    new_params = Map.put(form.params, field, new_value)

    AshPhoenix.Form.validate(form, new_params)
  end

  # Helper functions for Cinder integration

  defp can_render_table?(assigns) do
    # Don't render if we have tables but none selected
    if assigns[:tables] not in [[], nil] && !assigns[:table] do
      false
    else
      # Render if we have no arguments, or if arguments have been submitted
      assigns.action.arguments == [] || assigns.params["args"]
    end
  end

  defp build_cinder_query(assigns) do
    # When there are validated form arguments, extract the source query from the form
    # which already has arguments properly applied. Otherwise build a fresh query.
    query =
      if assigns.params["args"] && assigns.query do
        assigns.query.source
      else
        Ash.Query.for_read(assigns.resource, assigns.action.name)
      end

    # Ensure table columns are loaded
    query
    |> Ash.Query.select([])
    |> Ash.Query.load(AshAdmin.Resource.table_columns(assigns.resource))
  end

  defp get_page_size(assigns) do
    if assigns.action.pagination do
      assigns.action.pagination.default_limit ||
        assigns.action.pagination.max_page_size || 25
    else
      25
    end
  end
end
