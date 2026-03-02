defmodule AshAdmin.Components.Sidebar do
  @moduledoc false
  use Phoenix.LiveComponent

  alias AshAdmin.Components.TopNav.DropdownHelper

  attr :domains, :any, required: true
  attr :domain, :any, required: true
  attr :resource, :any, required: true
  attr :prefix, :any, required: true
  attr :open, :boolean, default: false

  # Actor/auth/tenant assigns
  attr :actor, :any, default: nil
  attr :actor_domain, :any, default: nil
  attr :actor_resources, :any, default: []
  attr :actor_paused, :boolean, default: false
  attr :actor_tenant, :any, default: nil
  attr :authorizing, :boolean, default: true
  attr :tenant, :any, default: nil
  attr :tenant_mode, :atom, default: nil
  attr :tenant_options, :list, default: []
  attr :tenant_suggestions, :list, default: []
  attr :editing_tenant, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="hidden md:flex md:w-64 md:shrink-0">
      <%!-- Mobile sidebar --%>
      <aside class={[
        "fixed inset-y-0 left-0 z-40 w-72 transform transition-transform duration-200 ease-in-out md:hidden",
        "bg-slate-900 dark:bg-slate-900 flex flex-col",
        if(@open, do: "translate-x-0", else: "-translate-x-full")
      ]}>
        {render_sidebar_content(assigns)}
      </aside>

      <%!-- Desktop sidebar --%>
      <aside class="flex flex-col w-64 bg-slate-900 dark:bg-slate-900 overflow-y-auto">
        {render_sidebar_content(assigns)}
      </aside>
    </div>
    """
  end

  defp render_sidebar_content(assigns) do
    ~H"""
    <%!-- Title --%>
    <div class="px-4 py-4 border-b border-slate-700/50">
      <.link
        navigate={@prefix}
        class="text-lg font-semibold text-white hover:text-slate-300 transition-colors"
      >
        Ash Admin
      </.link>
    </div>

    <%!-- Domain/Resource navigation --%>
    <nav class="flex-1 overflow-y-auto px-3 py-3 space-y-1">
      <div :for={domain <- @domains}>
        <button
          type="button"
          phx-click="toggle_domain"
          phx-value-domain={AshAdmin.Domain.name(domain)}
          phx-target={@myself}
          class="w-full flex items-center justify-between px-2 py-2 text-sm font-medium text-slate-300 hover:text-white hover:bg-slate-800 rounded-md transition-colors"
        >
          <span>{AshAdmin.Domain.name(domain)}</span>
          <AshAdmin.CoreComponents.icon
            name={
              if domain_expanded?(@expanded_domains, domain),
                do: "hero-chevron-down-mini",
                else: "hero-chevron-right-mini"
            }
            class="h-4 w-4 text-slate-500"
          />
        </button>

        <div :if={domain_expanded?(@expanded_domains, domain)} class="ml-2 space-y-0.5 mt-0.5">
          <% groups = DropdownHelper.dropdown_groups(@prefix, @resource, domain) %>
          <% group_labels = DropdownHelper.dropdown_group_labels(domain) %>
          <div :for={{group, group_index} <- Enum.with_index(groups)}>
            <div
              :if={group_label(group, group_index, group_labels)}
              class="px-2 pt-2 pb-1 text-xs font-semibold text-slate-500 uppercase tracking-wider"
            >
              {group_label(group, group_index, group_labels)}
            </div>
            <.link
              :for={item <- group}
              navigate={item.to}
              class={[
                "block px-3 py-1.5 text-sm rounded-md transition-colors",
                if(item.active,
                  do: "bg-slate-700 text-white font-medium",
                  else: "text-slate-400 hover:text-white hover:bg-slate-800"
                )
              ]}
            >
              {item.text}
            </.link>
          </div>
        </div>
      </div>
    </nav>

    <%!-- Status Panel --%>
    <div class="border-t border-slate-700/50 px-3 py-3 space-y-2">
      <%!-- Actor --%>
      <div :if={@actor_resources != []} id="sidebar-actor" phx-hook="Actor" class="space-y-1.5">
        <div class="flex items-center justify-between">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Actor</span>
        </div>
        <div :if={@actor} class="flex items-center gap-2 text-sm">
          <button
            type="button"
            phx-click="toggle_actor_paused"
            class="flex-shrink-0"
            title={
              if @actor_paused,
                do: "Actor paused — click to resume",
                else: "Actor active — click to pause"
            }
          >
            <span class={[
              "inline-block h-2.5 w-2.5 rounded-full transition-colors",
              if(@actor_paused, do: "bg-slate-500", else: "bg-emerald-400")
            ]} />
          </button>
          <span class="text-slate-300 truncate" title={user_display(@actor, @actor_tenant)}>
            {user_display(@actor, @actor_tenant)}
          </span>
          <button
            type="button"
            phx-click="clear_actor"
            class="flex-shrink-0 text-slate-500 hover:text-slate-300"
            title="Clear actor"
          >
            <AshAdmin.CoreComponents.icon name="hero-x-mark-mini" class="h-4 w-4" />
          </button>
        </div>
        <div :if={!@actor} class="text-sm text-slate-500">
          <span>No actor</span>
          <span :for={{domain, resource} <- @actor_resources} class="ml-1">
            <.link
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}&action_type=read"}
              class="text-slate-400 hover:text-white underline"
            >
              Set {AshAdmin.Resource.name(resource)}
            </.link>
          </span>
        </div>
      </div>

      <%!-- Authorizing --%>
      <div :if={@actor_resources != []} class="flex items-center gap-2">
        <button
          type="button"
          phx-click="toggle_authorizing"
          class="flex items-center gap-2 text-sm"
        >
          <span class={[
            "inline-block h-2.5 w-2.5 rounded-full transition-colors",
            if(@authorizing, do: "bg-emerald-400", else: "bg-slate-500")
          ]} />
          <span class={if(@authorizing, do: "text-slate-300", else: "text-slate-500")}>
            {if @authorizing, do: "Auth enforced", else: "Auth bypassed"}
          </span>
        </button>
      </div>

      <%!-- Tenant --%>
      <div
        :if={show_tenant?(@domains, @tenant_mode)}
        id="sidebar-tenant"
        phx-hook="Tenant"
        class="relative"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Tenant</span>
        </div>
        {render_tenant(assigns)}
      </div>
    </div>
    """
  end

  defp render_tenant(%{tenant_mode: :dropdown} = assigns) do
    ~H"""
    <div class="mt-1">
      <.form for={to_form(%{}, as: :tenant)} phx-change="set_tenant">
        <select
          name="tenant"
          class="w-full text-sm rounded-md bg-slate-800 border-slate-700 text-slate-300 focus:border-slate-500 focus:ring-slate-500"
        >
          <option value="">No tenant</option>
          <option :for={t <- @tenant_options} value={t} selected={t == @tenant}>{t}</option>
        </select>
      </.form>
    </div>
    """
  end

  defp render_tenant(%{tenant_mode: :typeahead} = assigns) do
    ~H"""
    <div class="mt-1">
      <div :if={@editing_tenant}>
        <.form
          for={to_form(%{}, as: :tenant)}
          phx-submit="set_tenant"
          phx-change="search_tenants"
          id="tenant-typeahead-form"
        >
          <ul
            :if={@tenant_suggestions != []}
            id="tenant-suggestions"
            phx-hook="PositionAbove"
            class="fixed z-50 bg-slate-800 border border-slate-700 rounded-md shadow-lg max-h-40 overflow-auto"
          >
            <li :for={s <- @tenant_suggestions}>
              <button
                type="button"
                phx-click="set_tenant"
                phx-value-tenant={s}
                class="w-full text-left px-3 py-1.5 text-sm text-slate-300 hover:bg-slate-700 cursor-pointer"
              >
                {s}
              </button>
            </li>
          </ul>
          <div class="relative">
            <input
              type="text"
              name="tenant"
              value={@tenant}
              class="w-full text-sm rounded-md bg-slate-800 border-slate-700 text-slate-300 focus:border-slate-500 focus:ring-slate-500"
              phx-debounce="300"
              autocomplete="off"
            />
            <button
              type="button"
              phx-click={Phoenix.LiveView.JS.dispatch("submit", to: "#tenant-typeahead-form")}
              class="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
            >
              <AshAdmin.CoreComponents.icon name="hero-check-mini" class="h-4 w-4" />
            </button>
          </div>
        </.form>
      </div>
      <div :if={!@editing_tenant} class="flex items-center gap-2 text-sm">
        <a href="#" phx-click="start_editing_tenant" class="text-slate-400 hover:text-white">
          {if @tenant, do: @tenant, else: "No tenant — Set"}
        </a>
        <button
          :if={@tenant}
          type="button"
          phx-click="clear_tenant"
          class="text-slate-500 hover:text-slate-300"
        >
          <AshAdmin.CoreComponents.icon name="hero-x-mark-mini" class="h-4 w-4" />
        </button>
      </div>
    </div>
    """
  end

  defp render_tenant(assigns) do
    ~H"""
    <div class="mt-1">
      <div :if={@editing_tenant}>
        <.form for={to_form(%{}, as: :tenant)} phx-submit="set_tenant" id="tenant-form">
          <div class="flex items-center gap-1">
            <input
              type="text"
              name="tenant"
              value={@tenant}
              class="flex-1 text-sm rounded-md bg-slate-800 border-slate-700 text-slate-300 focus:border-slate-500 focus:ring-slate-500"
            />
            <button
              type="button"
              phx-click={Phoenix.LiveView.JS.dispatch("submit", to: "#tenant-form")}
              class="text-slate-400 hover:text-white"
            >
              <AshAdmin.CoreComponents.icon name="hero-check-mini" class="h-4 w-4" />
            </button>
          </div>
        </.form>
      </div>
      <div :if={!@editing_tenant} class="flex items-center gap-2 text-sm">
        <a href="#" phx-click="start_editing_tenant" class="text-slate-400 hover:text-white">
          {if @tenant, do: @tenant, else: "No tenant — Set"}
        </a>
        <button
          :if={@tenant}
          type="button"
          phx-click="clear_tenant"
          class="text-slate-500 hover:text-slate-300"
        >
          <AshAdmin.CoreComponents.icon name="hero-x-mark-mini" class="h-4 w-4" />
        </button>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, :expanded_domains, MapSet.new())}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Auto-expand the domain containing the current resource
    socket =
      if assigns[:domain] do
        domain_name = AshAdmin.Domain.name(assigns.domain)

        if MapSet.member?(socket.assigns.expanded_domains, domain_name) do
          socket
        else
          assign(
            socket,
            :expanded_domains,
            MapSet.put(socket.assigns.expanded_domains, domain_name)
          )
        end
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("toggle_domain", %{"domain" => domain_name}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded_domains, domain_name) do
        MapSet.delete(socket.assigns.expanded_domains, domain_name)
      else
        MapSet.put(socket.assigns.expanded_domains, domain_name)
      end

    {:noreply, assign(socket, :expanded_domains, expanded)}
  end

  defp domain_expanded?(expanded_domains, domain) do
    MapSet.member?(expanded_domains, AshAdmin.Domain.name(domain))
  end

  defp group_label(group, group_index, group_labels) do
    # Get the group key from the first item
    case List.first(group) do
      %{group: nil} ->
        nil

      %{group: group_key} ->
        case group_labels do
          labels when is_list(labels) ->
            Keyword.get(labels, group_key, Phoenix.Naming.humanize(group_key))

          labels when is_map(labels) ->
            Map.get(labels, group_key, Phoenix.Naming.humanize(group_key))

          _ ->
            Phoenix.Naming.humanize(group_key)
        end

      _ ->
        if group_index > 0, do: nil, else: nil
    end
  end

  defp show_tenant?(_domains, tenant_mode) when tenant_mode in [:dropdown, :typeahead], do: true

  defp show_tenant?(domains, _tenant_mode) do
    Enum.any?(domains, fn domain ->
      domain
      |> AshAdmin.Domain.show_resources()
      |> Enum.any?(fn resource ->
        Ash.Resource.Info.multitenancy_strategy(resource)
      end)
    end)
  end

  defp user_display(actor, nil) do
    name = AshAdmin.Resource.name(actor.__struct__)

    case Ash.Resource.Info.primary_key(actor.__struct__) do
      [field] ->
        "#{name}: #{Map.get(actor, field)}"

      fields ->
        Enum.map_join(fields, ", ", fn field ->
          "#{field}: #{Map.get(actor, field)}"
        end)
    end
  end

  defp user_display(actor, tenant) do
    user_display(actor, nil) <> " (#{tenant})"
  end
end
