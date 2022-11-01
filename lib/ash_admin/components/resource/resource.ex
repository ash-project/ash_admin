defmodule AshAdmin.Components.Resource do
  @moduledoc false
  use Surface.LiveComponent

  require Ash.Query

  alias AshAdmin.Components.Resource.{Show, Form, Info, Nav, DataTable}

  # prop hide_filter, :boolean, default: true
  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(tab, :string, required: true)
  prop(action, :any)
  prop(actor, :any, required: true)
  prop(set_actor, :event, required: true)
  prop(authorizing, :boolean, required: true)
  prop(tenant, :string, required: true)
  prop(url_path, :string, default: "")
  prop(params, :map, default: %{})
  prop(primary_key, :any, default: nil)
  prop(record, :any, default: nil)
  prop(table, :any, default: nil)
  prop(tables, :any, default: nil)
  prop(prefix, :any, default: nil)
  prop(action_type, :atom)
  prop(polymorphic_actions, :any)

  data(filter_open, :boolean, default: false)
  slot(default)

  def render(assigns) do
    ~F"""
    <div class="content-center h-screen">
      <Nav
        resource={@resource}
        api={@api}
        tab={@tab}
        action={@action}
        table={@table}
        prefix={@prefix}
      />
      <div class="mx-24 relative grid grid-cols-1 justify-items-center">
      </div>
      <#slot />
      <div :if={@record && match?({:ok, record} when not is_nil(record), @record) && @tab == "update"}>
        {{:ok, record} = @record
        nil}
        <Form
          type={:update}
          record={record}
          resource={@resource}
          url_path={@url_path}
          params={@params}
          action={@action}
          api={@api}
          id={update_id(@resource)}
          actor={@actor}
          set_actor={@set_actor}
          authorizing={@authorizing}
          tenant={@tenant}
          table={@table}
          tables={@tables}
          prefix={@prefix}
        />
      </div>
      <div :if={@record && match?({:ok, record} when not is_nil(record), @record) && @tab == "destroy"}>
        {{:ok, record} = @record
        nil}
        <Form
          type={:destroy}
          record={record}
          resource={@resource}
          url_path={@url_path}
          action={@action}
          params={@params}
          set_actor={@set_actor}
          api={@api}
          id={destroy_id(@resource)}
          actor={@actor}
          authorizing={@authorizing}
          tenant={@tenant}
          table={@table}
          tables={@tables}
          prefix={@prefix}
        />
      </div>
      <Show
        :if={@tab == "show" && match?({:ok, %_{}}, @record)}
        resource={@resource}
        api={@api}
        id={show_id(@resource)}
        record={unwrap(@record)}
        actor={@actor}
        authorizing={@authorizing}
        tenant={@tenant}
        set_actor={@set_actor}
        table={@table}
        prefix={@prefix}
      />
      <Info
        :if={@tab == "info" || (is_nil(@tab) && is_nil(@action_type))}
        resource={@resource}
        api={@api}
        prefix={@prefix}
      />
      <Form
        :if={@tab == "create"}
        type={:create}
        resource={@resource}
        url_path={@url_path}
        params={@params}
        api={@api}
        set_actor={@set_actor}
        action={@action}
        id={create_id(@resource)}
        actor={@actor}
        authorizing={@authorizing}
        tenant={@tenant}
        table={@table}
        tables={@tables}
        prefix={@prefix}
        polymorphic_actions={@polymorphic_actions}
      />
      <DataTable
        :if={@action_type == :read && @tab != "show"}
        polymorphic_actions={@polymorphic_actions}
        resource={@resource}
        action={@action}
        actor={@actor}
        api={@api}
        url_path={@url_path}
        params={@params}
        set_actor={@set_actor}
        id={data_table_id(@resource)}
        authorizing={@authorizing}
        table={@table}
        tables={@tables}
        prefix={@prefix}
        tenant={@tenant}
      />
    </div>
    """
  end

  defp unwrap({:ok, val}), do: val

  defp data_table_id(resource) do
    "#{resource}_table"
  end

  defp create_id(resource) do
    "#{resource}_create"
  end

  defp update_id(resource) do
    "#{resource}_update"
  end

  defp destroy_id(resource) do
    "#{resource}_destroy"
  end

  defp show_id(resource) do
    "#{resource}_show"
  end
end
