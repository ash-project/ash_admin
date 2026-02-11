# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.DataTable do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.Helpers
  alias AshAdmin.Components.Resource.Table
  alias AshAdmin.Themes.AshAdminTheme

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
      <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen">
        <div
          :if={@action.arguments != []}
          class="mx-4 md:mx-16 mt-4 md:mt-10"
        >
          <div class="shadow-lg overflow-hidden sm:rounded-md bg-white" style="max-width: 42rem;">
            <div class="px-6 py-6">
              <.form
                :let={form}
                :if={@query}
                as={:query}
                for={@query}
                phx-change="validate"
                phx-submit="save"
                phx-target={@myself}
              >
                {AshAdmin.Components.Resource.Form.render_attributes(
                  assigns,
                  @resource,
                  @action,
                  form
                )}
                <div class="py-3 text-right">
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

        <div :if={@tables != []} class="mx-4 md:mx-16 mt-4 md:mt-10">
          <div class="px-6 py-4">
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

        <div
          :if={@action.arguments == [] || @params["args"]}
          class="h-full overflow-auto mx-4 md:mx-16 mt-4 md:mt-10"
        >
          <div class="shadow-lg overflow-auto sm:rounded-md bg-white">
            <div class="px-2">
              <div :if={@ash_query} class="px-6 pt-6">
                <button
                  phx-click="toggle_filters"
                  phx-target={@myself}
                  class="inline-flex items-center gap-2 py-2 px-4 border border-indigo-600 text-sm font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <AshAdmin.CoreComponents.icon
                    name={if @show_filters, do: "hero-funnel-solid", else: "hero-funnel"}
                    class="h-4 w-4"
                  />
                  {if @show_filters, do: "Hide Filters", else: "Filters"}
                </button>
              </div>
              <Cinder.collection
                :if={@ash_query}
                query={@ash_query}
                actor={@actor}
                tenant={@tenant}
                page_size={@page_size}
                pagination={@pagination_mode}
                show_filters={@show_filters}
                query_opts={[authorize?: @authorizing]}
                theme={AshAdminTheme}
                id={"cinder-table-#{@resource}"}
              >
                <!-- Generate columns with simple sortable/filterable configuration -->
                <:col
                  :let={record}
                  :for={field_name <- AshAdmin.Resource.table_columns(@resource)}
                  field={to_string(field_name)}
                  label={to_name(field_name)}
                  filter={filterable?(@resource, field_name)}
                  sort={sortable?(@resource, field_name)}
                >
                  {render_field_value(record, field_name, assigns)}
                </:col>
                
    <!-- Action buttons column -->
                <:col :let={record} :if={actions?(@resource)} label="Actions">
                  <div class="flex h-max justify-items-center">
                    <div :if={AshAdmin.Resource.show_action(@resource)}>
                      <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&table=#{@table}&primary_key=#{encode_primary_key(record)}&action_type=read"}>
                        <AshAdmin.CoreComponents.icon
                          name="hero-information-circle-solid"
                          class="h-5 w-5 text-gray-500"
                        />
                      </.link>
                    </div>

                    <div :if={AshAdmin.Helpers.primary_action(@resource, :update)}>
                      <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=update&table=#{@table}&primary_key=#{encode_primary_key(record)}"}>
                        <AshAdmin.CoreComponents.icon
                          name="hero-pencil-solid"
                          class="h-5 w-5 text-gray-500"
                        />
                      </.link>
                    </div>

                    <div :if={AshAdmin.Helpers.primary_action(@resource, :destroy)}>
                      <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=destroy&table=#{@table}&primary_key=#{encode_primary_key(record)}"}>
                        <AshAdmin.CoreComponents.icon
                          name="hero-x-circle-solid"
                          class="h-5 w-5 text-gray-500"
                        />
                      </.link>
                    </div>

                    <button
                      :if={AshAdmin.Resource.actor?(@resource)}
                      phx-click="set_actor"
                      phx-value-resource={@resource}
                      phx-value-domain={@domain}
                      phx-value-pkey={encode_primary_key(record)}
                    >
                      <AshAdmin.CoreComponents.icon
                        name="hero-key-solid"
                        class="h-5 w-5 text-gray-500"
                      />
                    </button>
                  </div>
                </:col>
              </Cinder.collection>
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
     |> assign_new(:show_filters, fn -> false end)}
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

      # Build the Ash query for Cinder by extracting from the AshPhoenix.Form
      # Only pass the query to Cinder if the form has no validation errors
      socket =
        if run_now? && (socket.assigns[:tables] in [[], nil] || socket.assigns[:table]) do
          ash_query = socket.assigns.query.source

          if ash_query.errors == [] do
            assign(socket, :ash_query, ash_query)
          else
            assign(socket, :ash_query, nil)
          end
        else
          assign(socket, :ash_query, nil)
        end

      {page_size, pagination_mode} = pagination_config(socket.assigns.action)
      socket = assign(socket, page_size: page_size, pagination_mode: pagination_mode)

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

  defp pagination_config(action) do
    case action.pagination do
      falsy when falsy in [nil, false] ->
        {nil, nil}

      pagination ->
        page_size = pagination.default_limit || pagination.max_page_size || 100

        pagination_mode =
          if pagination.keyset? && !pagination.offset? do
            :keyset
          else
            :offset
          end

        {page_size, pagination_mode}
    end
  end

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

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

  # Field rendering - delegate to existing Table component logic
  defp render_field_value(record, field_name, assigns) do
    attribute = Ash.Resource.Info.field(assigns.resource, field_name)
    format_fields = AshAdmin.Resource.format_fields(assigns.resource)
    show_sensitive_fields = AshAdmin.Resource.show_sensitive_fields(assigns.resource)

    if attribute do
      Table.render_attribute(
        assigns.domain,
        record,
        attribute,
        format_fields,
        show_sensitive_fields,
        assigns.actor,
        nil
      )
    else
      "..."
    end
  rescue
    _ ->
      "..."
  end

  # Check if a field should be sortable
  defp sortable?(resource, field_name) do
    sortable_columns = AshAdmin.Resource.table_sortable_columns(resource)

    case sortable_columns do
      # If not specified, everything is sortable
      nil -> true
      list -> field_name in list
    end
  end

  # Check if a field should be filterable
  defp filterable?(resource, field_name) do
    filterable_columns = AshAdmin.Resource.table_filterable_columns(resource)

    case filterable_columns do
      # If not specified, everything is filterable
      nil -> true
      list -> field_name in list && has_attribute?(resource, field_name)
    end
  end

  # Check if field is an actual resource attribute (not a relationship or calculated field)
  defp has_attribute?(resource, field_name) do
    Ash.Resource.Info.field(resource, field_name) != nil
  end

  defp actions?(resource) do
    AshAdmin.Helpers.primary_action(resource, :update) ||
      AshAdmin.Resource.show_action(resource) ||
      AshAdmin.Resource.actor?(resource) ||
      AshAdmin.Helpers.primary_action(resource, :destroy)
  end
end
