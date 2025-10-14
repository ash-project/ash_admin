# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource do
  @moduledoc false
  use Phoenix.LiveComponent

  require Ash.Query

  alias AshAdmin.Components.Resource.{DataTable, Form, GenericAction, Info, Nav, Show}

  # prop hide_filter, :boolean, default: true
  attr :resource, :any, required: true
  attr :domain, :any, required: true
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
    <div class="flex flex-col">
      <Nav.nav resource={@resource} domain={@domain} action={@action} table={@table} prefix={@prefix} />
      <div class="flex-1 p-6">
        <div :if={@record && match?({:error, error} when not is_nil(error), @record)}>
          <p>Error loading record</p>
        </div>
        <div :if={
          @record && match?({:ok, record} when not is_nil(record), @record) &&
            @action_type == :update
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
          @record && match?({:ok, record} when not is_nil(record), @record) &&
            @action_type == :destroy
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
          :if={match?({:ok, %_{}}, @record) && @action_type == :read}
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
        <Info.info :if={is_nil(@action_type)} resource={@resource} domain={@domain} prefix={@prefix} />
        <.live_component
          :if={@action_type == :create}
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
          :if={@action_type == :read && !match?({:ok, %_{}}, @record)}
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
        <.live_component
          :if={@action_type == :action}
          module={GenericAction}
          id={action_id(@resource)}
          resource={@resource}
          action={@action}
          actor={@actor}
          domain={@domain}
          url_path={@url_path}
          params={@params}
          authorizing={@authorizing}
          table={@table}
          prefix={@prefix}
          tenant={@tenant}
        />
      </div>
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

  defp action_id(resource) do
    "#{resource}_action"
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
