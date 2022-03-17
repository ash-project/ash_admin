defmodule AshAdmin.Components.TopNav do
  @moduledoc false
  use Surface.LiveComponent
  alias Surface.Components.LiveRedirect
  alias AshAdmin.Components.TopNav.{ActorSelect, DrawerDropdown, TenantForm, Dropdown}

  data(nav_collapsed, :boolean, default: true)

  prop(api, :any, required: true)
  prop(resource, :any, required: true)
  prop(actor_resources, :any, required: true)
  prop(apis, :any, required: true)
  prop(tenant, :any, required: true)
  prop(clear_tenant, :event)
  prop(set_tenant, :event)
  prop(toggle_authorizing, :event, required: true)
  prop(toggle_actor_paused, :event, required: true)
  prop(clear_actor, :event, required: true)
  prop(authorizing, :boolean, required: true)
  prop(actor_paused, :boolean, required: true)
  prop(actor, :any, required: true)
  prop(actor_api, :any, required: true)
  prop(prefix, :any, required: true)

  def render(assigns) do
    ~F"""
    <nav x-data="{ navOpen: false }" @keydown.window.escape="navOpen = false" class="bg-gray-800">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center w-full">
            <div class="flex-shrink-0">
              <h3 class="text-white text-lg">
                <LiveRedirect to={@prefix}>
                  Admin
                </LiveRedirect>
              </h3>
            </div>
            <div class="hidden md:block w-full">
              <div class="flex justify-between">
                <div class="ml-10 flex items-center">
                  {#for api <- @apis}
                    <Dropdown
                      active={api == @api}
                      class="mr-1"
                      id={AshAdmin.Api.name(api) <> "_api_nav"}
                      name={AshAdmin.Api.name(api)}
                      groups={dropdown_groups(@prefix, @resource, api)}
                    />
                  {/for}
                </div>
                <div class="ml-10 flex items-center">
                  <ActorSelect
                    :if={@actor_resources != []}
                    actor_resources={@actor_resources}
                    authorizing={@authorizing}
                    actor_paused={@actor_paused}
                    actor={@actor}
                    toggle_authorizing={@toggle_authorizing}
                    toggle_actor_paused={@toggle_actor_paused}
                    clear_actor={@clear_actor}
                    actor_api={@actor_api}
                    api={@api}
                    prefix={@prefix}
                  />
                  <TenantForm
                    :if={show_tenant_form?(@apis)}
                    tenant={@tenant}
                    id="tenant_editor"
                    set_tenant={@set_tenant}
                    clear_tenant={@clear_tenant}
                  />
                </div>
              </div>
            </div>
          </div>
          <div class="-mr-2 flex md:hidden">
            <button
              x-on:click="navOpen = !navOpen"
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:bg-gray-700 focus:text-white"
            >
              <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                <path
                  :class="{'hidden': navOpen, 'inline-flex': !navOpen }"
                  class="inline-flex"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
                <path
                  :class="{'hidden': !navOpen, 'inline-flex': navOpen }"
                  class="hidden"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>
      <div x-show="navOpen" class="md:hidden" x-cloak>
        <div class="relative px-2 pt-2 pb-3 sm:px-3">
          <div class="block px-4 py-2 text-sm">
            <ActorSelect
              :if={@actor_resources != []}
              actor_resources={@actor_resources}
              authorizing={@authorizing}
              actor_paused={@actor_paused}
              actor={@actor}
              toggle_authorizing={@toggle_authorizing}
              toggle_actor_paused={@toggle_actor_paused}
              clear_actor={@clear_actor}
              actor_api={@actor_api}
              api={@api}
              prefix={@prefix}
            />
          </div>
          <div class="block px-4 py-2 text-sm">
            <TenantForm
              :if={show_tenant_form?(@apis)}
              tenant={@tenant}
              id="tenant_editor_drawer"
              set_tenant={@set_tenant}
              clear_tenant={@clear_tenant}
            />
          </div>
          <DrawerDropdown
            :for={api <- @apis}
            id={AshAdmin.Api.name(api) <> "_api_nav_drawer"}
            name={AshAdmin.Api.name(api)}
            groups={dropdown_groups(@prefix, @resource, api)}
          />
        </div>
      </div>
    </nav>
    """
  end

  defp dropdown_groups(prefix, current_resource, api) do
    [
      for resource <- Ash.Api.resources(api) do
        %{
          text: AshAdmin.Resource.name(resource),
          to:
            "#{prefix}?api=#{AshAdmin.Api.name(api)}&resource=#{AshAdmin.Resource.name(resource)}",
          active: resource == current_resource
        }
      end
    ]
  end

  def handle_event("collapse_nav", _, socket) do
    {:noreply, assign(socket, :nav_collapsed, !socket.assigns.nav_collapsed)}
  end

  defp show_tenant_form?(apis) do
    Enum.any?(apis, fn api ->
      api
      |> Ash.Api.resources()
      |> Enum.any?(fn resource ->
        Ash.Resource.Info.multitenancy_strategy(resource)
      end)
    end)
  end
end
