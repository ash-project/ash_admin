defmodule AshAdmin.Components.Resource do
  @moduledoc false
  use Phoenix.LiveComponent

  require Ash.Query

  alias AshAdmin.Components.Resource.{DataTable, Form, Info, Nav, Show}

  # prop hide_filter, :boolean, default: true
  attr :resource, :any, required: true
  attr :domain, :any, required: true
  attr :tab, :string, required: true
  attr :action, :any
  attr :actor, :any, required: true
  attr :authorizing, :boolean, required: true
  attr :tenant, :string, required: true
  attr :url_path, :string, default: ""
  attr :params, :map, default: %{}
  attr :primary_key, :any, default: nil
  attr :record, :any, default: nil
  attr :table, :any, default: nil
  attr :tables, :any, default: nil
  attr :prefix, :any, default: nil
  attr :action_type, :atom
  attr :polymorphic_actions, :any

  def render(assigns) do
    ~H"""
    <div class="h-screen">
      <Nav.nav
        resource={@resource}
        domain={@domain}
        tab={@tab}
        action={@action}
        table={@table}
        prefix={@prefix}
      />
      <div class="mx-24 relative grid grid-cols-1 justify-items-center"></div>
      <div :if={
        @record && match?({:ok, record} when not is_nil(record), @record) &&
          @tab == "update"
      }>
        <% {:ok, record} = @record %>
        <.live_component
          module={Form}
          polymorphic_actions={@polymorphic_actions}
          type={:update}
          record={record}
          resource={@resource}
          url_path={@url_path}
          params={@params}
          action={@action}
          domain={@domain}
          id={update_id(@resource)}
          actor={@actor}
          authorizing={@authorizing}
          tenant={@tenant}
          table={@table}
          tables={@tables}
          prefix={@prefix}
        />
      </div>
      <div :if={
        @record && match?({:ok, record} when not is_nil(record), @record) && @tab == "destroy"
      }>
        <% {:ok, record} = @record %>
        <.live_component
          module={Form}
          polymorphic_actions={@polymorphic_actions}
          type={:destroy}
          record={record}
          resource={@resource}
          url_path={@url_path}
          action={@action}
          params={@params}
          domain={@domain}
          id={destroy_id(@resource)}
          actor={@actor}
          authorizing={@authorizing}
          tenant={@tenant}
          table={@table}
          tables={@tables}
          prefix={@prefix}
        />
      </div>
      <.live_component
        :if={@tab == "show" && match?({:ok, %_{}}, @record)}
        module={Show}
        resource={@resource}
        domain={@domain}
        id={show_id(@resource)}
        record={unwrap(@record)}
        actor={@actor}
        authorizing={@authorizing}
        tenant={@tenant}
        table={@table}
        prefix={@prefix}
      />
      <Info.info
        :if={@tab == "info" || (is_nil(@tab) && is_nil(@action_type))}
        resource={@resource}
        domain={@domain}
        prefix={@prefix}
      />
      <.live_component
        :if={@tab == "create"}
        module={Form}
        type={:create}
        resource={@resource}
        url_path={@url_path}
        params={@params}
        domain={@domain}
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
      <.live_component
        :if={@action_type == :read && @tab != "show"}
        module={DataTable}
        polymorphic_actions={@polymorphic_actions}
        resource={@resource}
        action={@action}
        actor={@actor}
        domain={@domain}
        url_path={@url_path}
        params={@params}
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

  def mount(socket) do
    {:ok, assign(socket, :filter_open, false)}
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
