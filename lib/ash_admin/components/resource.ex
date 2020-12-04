defmodule AshAdmin.Components.Resource do
  use Surface.Component

  import AshAdmin.Helpers
  require Ash.Query

  alias AshAdmin.Components.Resource.{Info, Nav}
  alias AshPhoenix.Components.DataTable

  # prop hide_filter, :boolean, default: true
  prop resource, :any, required: true
  prop api, :any, required: true
  prop tab, :string, required: true
  prop action, :any
  prop actor, :any, required: true
  prop set_actor, :event, required: true
  prop authorize, :boolean, required: true
  prop tenant, :string, required: true

  def render(assigns) do
    ~H"""
    <div>
      <Nav
        resource={{ @resource }}
        api={{ @api }}
        tab={{ @tab }}
        action={{ @action }}/>
      <div class="container">
      <DataTable
        :if={{@tab == "data" && @action.type == :read}}
        table_class="table"
        id={{data_table_id(@resource)}}
        resource={{ @resource }}
        run_query={{run_query()}}
        query_context={{%{resource: @resource, api: @api, action: @action, authorize?: @authorize, tenant: @tenant, actor: @actor}}}
        filter_builder={{true}}
        show_header={{true}}
        loading={{true}}>
          <template slot="actions" :let={{ item: item}}>
            <button
            slot="actions"
            type="button"
            class="btn btn-outline-primary"
            :on-click={{@set_actor}}
            phx-value-resource={{@resource}}
            phx-value-api={{@api}}
            phx-value-action={{@action.name}}
            phx-value-pkey={{encode_primary_key(item)}}>
              <svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-key" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M0 8a4 4 0 0 1 7.465-2H14a.5.5 0 0 1 .354.146l1.5 1.5a.5.5 0 0 1 0 .708l-1.5 1.5a.5.5 0 0 1-.708 0L13 9.207l-.646.647a.5.5 0 0 1-.708 0L11 9.207l-.646.647a.5.5 0 0 1-.708 0L9 9.207l-.646.647A.5.5 0 0 1 8 10h-.535A4 4 0 0 1 0 8zm4-3a3 3 0 1 0 2.712 4.285A.5.5 0 0 1 7.163 9h.63l.853-.854a.5.5 0 0 1 .708 0l.646.647.646-.647a.5.5 0 0 1 .708 0l.646.647.646-.647a.5.5 0 0 1 .708 0l.646.647.793-.793-1-1h-6.63a.5.5 0 0 1-.451-.285A3 3 0 0 0 4 5z"/>
                <path d="M4 8a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"/>
              </svg>
            </button>
          </template>
          <template slot="error" :let={{ error: error}}>
            {{ inspect(error) }}
          </template>
      </DataTable>
      </div>
      <Info :if={{@tab == "info"}} resource={{@resource}} api={{@api}}/>
    </div>
    """
  end

  defp data_table_id(resource) do
    "#{resource}_table"
  end

  defp run_query() do
    fn filter, sort, fields, context ->
      context.resource
      |> Ash.Query.filter(^filter)
      |> Ash.Query.sort(sort)
      |> Ash.Query.load(fields)
      |> Ash.Query.set_tenant(context.tenant)
      |> context.api.read(
        action: context.action.name,
        actor: context.actor,
        authorize?: context.authorize?
      )
    end
  end

  # def update(assigns, socket) do
  #   socket =
  #     socket
  #     |> assign(assigns)
  #     |> assign(:primary_key, Ash.Resource.primary_key(assigns.resource))
  #     |> assign(:has_create_action, has_create_action?)
  #     |> assign(:callback,
  #     end)

  #   case assigns[:action_type] do
  #     nil ->
  #       {:ok, socket |> assign(:action, nil)}

  #     action_type ->
  #       action = Ash.Resource.action(assigns.resource, assigns.action_name, action_type)
  #       {:ok, socket |> assign(:action, action)}
  #   end
  # end

  # def handle_event("toggle_filter", _, socket) do
  #   {:noreply, assign(socket, :hide_filter, !socket.assigns.hide_filter)}
  # end

  # def render(assigns) do
  #   ~L"""
  #   <div>

  #   </div>
  #   """
  # end
end
