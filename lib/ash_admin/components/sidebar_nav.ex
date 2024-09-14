defmodule AshAdmin.Components.SidebarNav do
  @moduledoc false
  use Phoenix.LiveComponent
  import AshAdmin.Helpers
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
    <div class="flex w-64 flex-col">
      <div class="flex min-h-0 flex-1 flex-col w-24">
        <div class=" flex flex-1 flex-col space-y-1 overflow-y-auto px-2 pt-5 pb-4">
          <%= for {group, things} <- dropdown_groups(@prefix, @resource, @domains) do %>
            <div class="flex flex-col">
              <%= group %>
              <%= Enum.count(things) %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  #   for resource <- AshAdmin.Domain.show_resources(domain) do
  #     %{
  #       text: AshAdmin.Resource.name(resource),
  #       to:
  #         "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}",
  #       active: resource == current_resource,
  #       group: AshAdmin.Resource.resource_group(resource)
  #     }
  #   end
  #   |> Enum.group_by(fn resource -> resource.group end)
  #   |> Enum.sort_by(fn {label, _items} -> label || "_____always_put_me_last" end)
  #   |> Keyword.values()

  # <a
  #   href="/admin/users"
  #   data-phx-link="redirect"
  #   data-phx-link-state="push"
  #   class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer bg-base-300 text-base-content "
  #   current_url="https://demo.backpex.live/admin/users"
  # >
  #   <span class="hero-user h-5 w-5" aria-hidden="true" fill="currentColor" viewbox="0 0 24 24">
  #   </span>
  #   Users
  # </a>
  # <a
  #   href="/admin/addresses"
  #   data-phx-link="redirect"
  #   data-phx-link-state="push"
  #   class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #   current_url="https://demo.backpex.live/admin/users"
  # >
  #   <span
  #     class="hero-building-office-2 h-5 w-5"
  #     aria-hidden="true"
  #     fill="currentColor"
  #     viewbox="0 0 24 24"
  #   >
  #   </span>
  #   Addresses
  # </a>
  # <a
  #   href="/admin/products"
  #   data-phx-link="redirect"
  #   data-phx-link-state="push"
  #   class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #   current_url="https://demo.backpex.live/admin/users"
  # >
  #   <span
  #     class="hero-shopping-bag h-5 w-5"
  #     aria-hidden="true"
  #     fill="currentColor"
  #     viewbox="0 0 24 24"
  #   >
  #   </span>
  #   Products
  # </a>
  # <a
  #   href="/admin/invoices"
  #   data-phx-link="redirect"
  #   data-phx-link-state="push"
  #   class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #   current_url="https://demo.backpex.live/admin/users"
  # >
  #   <span
  #     class="hero-document-text h-5 w-5"
  #     aria-hidden="true"
  #     fill="currentColor"
  #     viewbox="0 0 24 24"
  #   >
  #   </span>
  #   Invoices
  # </a>
  # <a
  #   href="/admin/film-reviews"
  #   data-phx-link="redirect"
  #   data-phx-link-state="push"
  #   class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #   current_url="https://demo.backpex.live/admin/users"
  # >
  #   <span class="hero-film h-5 w-5" aria-hidden="true" fill="currentColor" viewbox="0 0 24 24">
  #   </span>
  #   Film Reviews
  # </a>
  # <div
  #   x-data="{open: localStorage.getItem('section-opened-blog')  === 'true'}"
  #   x-init="$watch('open', val => localStorage.setItem('section-opened-blog', val))"
  # >
  #   <div
  #     @click="open = !open"
  #     class=" group mt-2 flex cursor-pointer items-center space-x-1 p-2"
  #   >
  #     <div class="pr-1">
  #       <span
  #         class="hero-chevron-down-solid h-5 w-5 transition duration-75 -rotate-90"
  #         aria-hidden="true"
  #         fill="currentColor"
  #         viewbox="0 0 24 24"
  #         x-bind:class="open ? '' : '-rotate-90'"
  #       >
  #       </span>
  #     </div>
  #     <div class="text-base-content flex gap-2 text-sm font-semibold uppercase">
  #       Blog
  #     </div>
  #   </div>
  #   <div
  #     class="flex-col space-y-1"
  #     x-show="open"
  #     x-transition=""
  #     x-transition.duration.75ms=""
  #     style="display: none;"
  #   >
  #     <a
  #       href="/admin/posts"
  #       data-phx-link="redirect"
  #       data-phx-link-state="push"
  #       class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #       current_url="https://demo.backpex.live/admin/users"
  #     >
  #       <span
  #         class="hero-book-open h-5 w-5"
  #         aria-hidden="true"
  #         fill="currentColor"
  #         viewbox="0 0 24 24"
  #       >
  #       </span>
  #       Posts
  #     </a>
  #     <a
  #       href="/admin/categories"
  #       data-phx-link="redirect"
  #       data-phx-link-state="push"
  #       class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #       current_url="https://demo.backpex.live/admin/users"
  #     >
  #       <span
  #         class="hero-tag h-5 w-5"
  #         aria-hidden="true"
  #         fill="currentColor"
  #         viewbox="0 0 24 24"
  #       >
  #       </span>
  #       Categories
  #     </a>
  #     <a
  #       href="/admin/tags"
  #       data-phx-link="redirect"
  #       data-phx-link-state="push"
  #       class="group flex items-center gap-2 rounded-btn px-2 py-2 space-x-2 hover:cursor-pointer text-base-content/95 hover:bg-base-100 "
  #       current_url="https://demo.backpex.live/admin/users"
  #     >
  #       <span
  #         class="hero-tag h-5 w-5"
  #         aria-hidden="true"
  #         fill="currentColor"
  #         viewbox="0 0 24 24"
  #       >
  #       </span>
  #       Tags
  #     </a>
  #   </div>
  # </div>

  defp dropdown_groups(prefix, current_resource, domains) do
    for domain <- domains, resource <- AshAdmin.Domain.show_resources(domain) do
      %{
        text: AshAdmin.Resource.name(resource),
        to:
          "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}",
        active: resource == current_resource,
        group:
          AshAdmin.Resource.resource_group(resource) ||
            AshAdmin.Domain.name(Ash.Resource.Info.domain(resource))
      }
    end
    |> Enum.group_by(fn resource -> resource.group end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  # defp dropdown_group_labels(domain) do
  #   AshAdmin.Domain.resource_group_labels(domain)
  # end

  def mount(socket) do
    {:ok, socket}
  end

  # def handle_event("collapse_nav", _, socket) do
  #   {:noreply, assign(socket, :nav_collapsed, !socket.assigns.nav_collapsed)}
  # end

  # def handle_event("close", _, socket) do
  #   {:noreply, assign(socket, :open, false)}
  # end

  # def handle_event("toggle", _, socket) do
  #   {:noreply, assign(socket, :open, !socket.assigns.open)}
  # end

  # defp show_tenant_form?(domains) do
  #   Enum.any?(domains, fn domain ->
  #     domain
  #     |> AshAdmin.Domain.show_resources()
  #     |> Enum.any?(fn resource ->
  #       Ash.Resource.Info.multitenancy_strategy(resource)
  #     end)
  #   end)
  # end
end
