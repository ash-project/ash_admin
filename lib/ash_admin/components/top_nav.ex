defmodule AshAdmin.Components.TopNav do
  use Surface.LiveComponent
  import AshAdmin.Helpers
  alias Surface.Components.LiveRedirect
  alias AshAdmin.Components.TopNav.{ActorSelect, TenantForm}

  data nav_collapsed, :boolean, default: true

  prop api, :any, required: true
  prop resource, :any, required: true
  prop actor_resources, :any, required: true
  prop apis, :any, required: true
  prop tenant, :any, required: true
  prop clear_tenant, :event
  prop set_tenant, :event
  prop toggle_authorizing, :event, required: true
  prop toggle_actor_paused, :event, required: true
  prop clear_actor, :event, required: true
  prop authorizing, :boolean, required: true
  prop actor_paused, :boolean, required: true
  prop actor, :any, required: true

  def render(assigns) do
    ~H"""
    <nav class="navbar navbar-expand-md fixed-top navbar-dark bg-dark">
      <LiveRedirect to={{ash_admin_path(@socket)}} class="navbar-brand">
        Admin
      </LiveRedirect>
      <button class="navbar-toggler p-0 border-0" type="button" data-toggle="offcanvas" :on-click="collapse_nav">
        <span class="navbar-toggler-icon"></span>
      </button>

      <div class={{ "navbar-collapse", "offcanvas-collapse", open: !@nav_collapsed }}>
        <ul class="navbar-nav mr-auto">
          <li class={{ "nav-item", "dropdown", active: @api == api }} :for.with_index={{{api, index} <- @apis }}>
            <a class="nav-link dropdown-toggle" href="#" id="api-{{index}}" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> {{ AshAdmin.Api.name(api) }} </a>
            <div class="dropdown-menu" aria-labelledby="api-{{index}}">
              <LiveRedirect
                class={{ "dropdown-item", active: resource == @resource }}
                to={{ash_admin_path(@socket, api, resource)}}
                :for={{resource <- Ash.Api.resources(api)}}>
                {{ AshAdmin.Resource.name(resource) }}
              </LiveRedirect>
            </div>
          </li>
        </ul>
        <TenantForm :if={{ show_tenant_form?(@apis) }} tenant={{ @tenant }} id="tenant_editor" set_tenant={{ @set_tenant }} clear_tenant={{ @clear_tenant }}/>
        <ActorSelect
          :if={{show_actor_select?(@actor_resources)}}
          actor_resources={{ @actor_resources }}
          authorizing={{ @authorizing }}
          actor_paused={{ @actor_paused }}
          actor={{ @actor }}
          toggle_authorizing={{ @toggle_authorizing }}
          toggle_actor_paused={{ @toggle_actor_paused }}
          clear_actor={{ @clear_actor }}
          />
      </div>
    </nav>
    """
  end

  def handle_event("collapse_nav", _, socket) do
    {:noreply, assign(socket, :nav_collapsed, !socket.assigns.nav_collapsed)}
  end

  defp show_tenant_form?(apis) do
    Enum.any?(apis, fn api ->
      api
      |> Ash.Api.resources()
      |> Enum.any?(fn resource ->
        Ash.Resource.multitenancy_strategy(resource)
      end)
    end)
  end

  defp show_actor_select?([]), do: false
  defp show_actor_select?(_), do: true
end
