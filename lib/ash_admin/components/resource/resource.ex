defmodule AshAdmin.Components.Resource do
  use Surface.LiveComponent

  require Ash.Query

  alias AshAdmin.Components.Resource.{Show, Form, Info, Nav, DataTable}

  # prop hide_filter, :boolean, default: true
  prop resource, :any, required: true
  prop api, :any, required: true
  prop tab, :string, required: true
  prop action, :any
  prop actor, :any, required: true
  prop set_actor, :event, required: true
  prop authorize, :boolean, required: true
  prop tenant, :string, required: true
  prop recover_filter, :any
  prop page_params, :any, default: []
  prop page_num, :integer, default: 1
  prop url_path, :string, default: ""
  prop params, :map, default: %{}
  prop primary_key, :any, default: nil
  prop record, :any, default: nil

  data filter_open, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="content-center h-screen">
      <Nav
        resource={{ @resource }}
        api={{ @api }}
        tab={{ @tab }}
        action={{ @action }}/>
      <div class="mx-24 relative grid grid-cols-1 justify-items-center">
      </div>
      <div :if={{@record && match?({:ok, record} when not is_nil(record), @record) && @tab == "update"}}>
        {{{:ok, record} = @record; nil}}
        <Form type={{:update}} record={{record}} resource={{@resource}} action={{IO.inspect(@action)}} api={{@api}} id={{update_id(@resource)}}/>
      </div>
      <Show :if={{@tab == "read" && match?({:ok, %_{}}, @record)}} resource={{@resource}} api={{@api}} record={{unwrap(@record)}}/>
      <Info :if={{@tab == "info"}} resource={{@resource}} api={{@api}}/>
      <Form :if={{@tab == "create"}} type={{:create}} resource={{@resource}} api={{@api}} action={{@action}} id={{create_id(@resource)}}/>
      <DataTable :if={{@tab == "data"}} resource={{@resource}} action={{@action}} api={{@api}} id={{data_table_id(@resource)}} authorize={{@authorize}}/>
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
end
