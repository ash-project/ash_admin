defmodule AshAdmin.Components.TopNav do
  @moduledoc false
  use Phoenix.LiveComponent
  import Tails
  alias AshAdmin.Components.TopNav.{ActorSelect, DrawerDropdown, Dropdown, TenantForm}

  attr :domain, :any, required: true
  attr :resource, :any, required: true
  attr :actor_resources, :any, required: true
  attr :domains, :any, required: true
  attr :tenant, :any, required: true
  attr :clear_tenant, :string
  attr :set_tenant, :string
  attr :toggle_authorizing, :string, required: true
  attr :toggle_actor_paused, :string, required: true
  attr :clear_actor, :string, required: true
  attr :authorizing, :boolean, required: true
  attr :actor_paused, :boolean, required: true
  attr :actor_tenant, :string, required: true
  attr :actor, :any, required: true
  attr :actor_domain, :any, required: true
  attr :prefix, :any, required: true

  def render(assigns) do
    ~H"""
    <nav phx-keydown="close" phx-key="escape" class="bg-gray-800" phx-target={@myself}>
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center w-full">
            <div class="flex-shrink-0">
              <h3 class="text-white text-lg">
                <.link navigate={@prefix}>
                  Admin
                </.link>
              </h3>
            </div>
            <div class="hidden md:block w-full">
              <div class="flex justify-between">
                <div class="ml-10 flex items-center">
                  <.live_component
                    :for={domain <- @domains}
                    module={Dropdown}
                    active={domain == @domain}
                    class="mr-1"
                    id={AshAdmin.Domain.name(domain) <> "_domain_nav"}
                    name={AshAdmin.Domain.name(domain)}
                    groups={dropdown_groups(@prefix, @resource, domain)}
                    group_labels={dropdown_group_labels(domain)}
                  />
                </div>
                <div class="ml-10 flex items-center">
                  <ActorSelect.actor_select
                    :if={@actor_resources != []}
                    actor_resources={@actor_resources}
                    authorizing={@authorizing}
                    actor_paused={@actor_paused}
                    actor_tenant={@actor_tenant}
                    actor={@actor}
                    toggle_authorizing={@toggle_authorizing}
                    toggle_actor_paused={@toggle_actor_paused}
                    clear_actor={@clear_actor}
                    actor_domain={@actor_domain}
                    domain={@domain}
                    prefix={@prefix}
                  />
                  <TenantForm.tenant_form
                    :if={show_tenant_form?(@domains)}
                    tenant={@tenant}
                    editing_tenant={@editing_tenant}
                    set_tenant={@set_tenant}
                    clear_tenant={@clear_tenant}
                  />
                </div>
              </div>
            </div>
          </div>
          <div class="-mr-2 flex md:hidden">
            <button
              phx-click="toggle"
              phx-target={@myself}
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:bg-gray-700 focus:text-white"
            >
              <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                <path
                  class={classes("inline-flex": !@open, hidden: @open)}
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
                <path
                  class={classes(hidden: !@open, "inline-flex": @open)}
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
      <div :if={@open} class="md:hidden" x-cloak>
        <div class="relative px-2 pt-2 pb-3 sm:px-3">
          <div class="block px-4 py-2 text-sm">
            <.live_component
              :if={@actor_resources != []}
              module={ActorSelect}
              actor_resources={@actor_resources}
              authorizing={@authorizing}
              actor_paused={@actor_paused}
              actor={@actor}
              toggle_authorizing={@toggle_authorizing}
              toggle_actor_paused={@toggle_actor_paused}
              clear_actor={@clear_actor}
              actor_domain={@actor_domain}
              domain={@domain}
              prefix={@prefix}
            />
          </div>
          <div class="block px-4 py-2 text-sm">
            <.live_component
              :if={show_tenant_form?(@domains)}
              module={TenantForm}
              tenant={@tenant}
              id="tenant_editor_drawer"
              set_tenant={@set_tenant}
              clear_tenant={@clear_tenant}
            />
          </div>
          <.live_component
            :for={domain <- @domains}
            module={DrawerDropdown}
            id={AshAdmin.Domain.name(domain) <> "_domain_nav_drawer"}
            name={AshAdmin.Domain.name(domain)}
            groups={dropdown_groups(@prefix, @resource, domain)}
            group_labels={dropdown_group_labels(domain)}
          />
        </div>
      </div>
    </nav>
    """
  end

  defp dropdown_groups(prefix, current_resource, domain) do
    for resource <- Ash.Domain.Info.resources(domain) do
      %{
        text: AshAdmin.Resource.name(resource),
        to:
          "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}",
        active: resource == current_resource,
        group: AshAdmin.Resource.resource_group(resource)
      }
    end
    |> Enum.group_by(fn resource -> resource.group end)
    |> Enum.sort_by(fn {label, _items} -> label || "_____always_put_me_last" end)
    |> Keyword.values()
  end

  defp dropdown_group_labels(domain) do
    AshAdmin.Domain.resource_group_labels(domain)
  end

  def mount(socket) do
    {:ok, assign(socket, nav_collapsed: false, open: false)}
  end

  def handle_event("collapse_nav", _, socket) do
    {:noreply, assign(socket, :nav_collapsed, !socket.assigns.nav_collapsed)}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :open, !socket.assigns.open)}
  end

  defp show_tenant_form?(domains) do
    Enum.any?(domains, fn domain ->
      domain
      |> Ash.Domain.Info.resources()
      |> Enum.any?(fn resource ->
        Ash.Resource.Info.multitenancy_strategy(resource)
      end)
    end)
  end
end
