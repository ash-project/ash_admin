defmodule AshAdmin.Components.Resource do
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
  prop(recover_filter, :any)
  prop(page_params, :any, default: [])
  prop(page_num, :integer, default: 1)
  prop(url_path, :string, default: "")
  prop(params, :map, default: %{})
  prop(primary_key, :any, default: nil)
  prop(record, :any, default: nil)

  data(filter_open, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <div class="content-center h-screen">
      <Nav resource={{ @resource }} api={{ @api }} tab={{ @tab }} action={{ @action }} />
      <div class="mx-24 relative grid grid-cols-1 justify-items-center">
      </div>
      <div :if={{ @record && match?({:ok, record} when not is_nil(record), @record) && @tab == "update" }}>
        {{ {:ok, record} = @record
        nil }}
        <Form
          type={{ :update }}
          record={{ record }}
          resource={{ @resource }}
          action={{ @action }}
          api={{ @api }}
          id={{ update_id(@resource) }}
          actor={{@actor}}
          set_actor={{@set_actor}}
          authorizing={{@authorizing}}
          tenant={{@tenant}}
        />
      </div>
      <div :if={{ @record && match?({:ok, record} when not is_nil(record), @record) && @tab == "destroy" }}>
        {{ {:ok, record} = @record
        nil }}
        <Form
          type={{ :destroy }}
          record={{ record }}
          resource={{ @resource }}
          action={{ @action }}
          set_actor={{@set_actor}}
          api={{ @api }}
          id={{ destroy_id(@resource) }}
          actor={{@actor}}
          authorizing={{@authorizing}}
          tenant={{@tenant}}
        />
      </div>
      <Show
        :if={{ @tab == "read" && match?({:ok, %_{}}, @record) }}
        resource={{ @resource }}
        api={{ @api }}
        id={{show_id(@resource)}}
        record={{ unwrap(@record) }}
        actor={{@actor}}
        authorizing={{@authorizing}}
        tenant={{@tenant}}
        set_actor={{@set_actor}}
      />
      <Info :if={{ @tab == "info" }} resource={{ @resource }} api={{ @api }} />
      <Form
        :if={{ @tab == "create" }}
        type={{ :create }}
        resource={{ @resource }}
        api={{ @api }}
        set_actor={{@set_actor}}
        action={{ @action }}
        id={{ create_id(@resource) }}
        actor={{@actor}}
        authorizing={{@authorizing}}
        tenant={{@tenant}}
      />
      <DataTable
        :if={{ @tab == "data" }}
        resource={{ @resource }}
        action={{ @action }}
        actor={{@actor}}
        api={{ @api }}
        url_path={{@url_path}}
        params={{@params}}
        set_actor={{ @set_actor }}
        id={{ data_table_id(@resource) }}
        authorizing={{@authorizing}}
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
