defmodule AshAdmin.Components.PageHeader do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :resource, :any, default: nil
  attr :domain, :any, default: nil
  attr :action, :any, default: nil
  attr :action_type, :atom, default: nil
  attr :table, :any, default: nil
  attr :prefix, :any, required: true

  def page_header(assigns) do
    ~H"""
    <header class="sticky top-0 z-20 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-700/50 px-4 h-14 flex items-center gap-3">
      <%!-- Mobile hamburger --%>
      <button
        type="button"
        phx-click="toggle_sidebar"
        class="md:hidden -ml-1 p-1.5 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
      >
        <AshAdmin.CoreComponents.icon name="hero-bars-3" class="h-5 w-5" />
      </button>

      <%!-- Resource name --%>
      <h1 :if={@resource} class="text-base font-semibold text-slate-900 dark:text-slate-100 truncate">
        {AshAdmin.Resource.name(@resource)}
      </h1>
      <h1 :if={!@resource} class="text-base font-semibold text-slate-900 dark:text-slate-100">
        Ash Admin
      </h1>

      <%!-- Read action switcher --%>
      <div :if={@resource} class="flex items-center gap-1 ml-2">
        {read_action_switcher(assigns)}
        {generic_actions_dropdown(assigns)}
      </div>

      <%!-- Spacer --%>
      <div class="flex-1" />

      <%!-- Create button --%>
      <div :if={@resource}>
        {create_action_button(assigns)}
      </div>
    </header>
    """
  end

  defp read_action_switcher(assigns) do
    read_actions = get_read_actions(assigns.resource)
    assigns = assign(assigns, :read_actions, read_actions)

    ~H"""
    <div :if={@read_actions != []} class="relative">
      <%= case @read_actions do %>
        <% [single] -> %>
          <.link
            navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read&action=#{single.name}&table=#{@table}"}
            class={[
              "inline-flex items-center px-2.5 py-1 text-sm rounded-md transition-colors",
              if(@action && @action.type == :read,
                do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
                else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              )
            ]}
          >
            {action_label(single)}
          </.link>
        <% actions -> %>
          <button
            type="button"
            phx-click={JS.toggle(to: "#read-actions-dropdown")}
            class={[
              "inline-flex items-center gap-1 px-2.5 py-1 text-sm rounded-md transition-colors",
              if(@action && @action.type == :read,
                do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
                else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              )
            ]}
          >
            {if @action && @action.type == :read, do: action_label(@action), else: "Read"}
            <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
          <div
            id="read-actions-dropdown"
            class="hidden absolute left-0 top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"
            phx-click-away={JS.hide(to: "#read-actions-dropdown")}
          >
            <.link
              :for={action <- actions}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read&action=#{action.name}&table=#{@table}"}
              class={[
                "block px-3 py-1.5 text-sm transition-colors",
                if(@action && @action.name == action.name && @action.type == :read,
                  do: "bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-slate-100",
                  else: "text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
                )
              ]}
            >
              {action_label(action)}
            </.link>
          </div>
      <% end %>
    </div>
    """
  end

  defp generic_actions_dropdown(assigns) do
    generic_actions = get_generic_actions(assigns.resource)
    assigns = assign(assigns, :generic_actions, generic_actions)

    ~H"""
    <div :if={@generic_actions != []} class="relative">
      <button
        type="button"
        phx-click={JS.toggle(to: "#generic-actions-dropdown")}
        class={[
          "inline-flex items-center gap-1 px-2.5 py-1 text-sm rounded-md transition-colors",
          if(@action && @action.type == :action,
            do: "bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 font-medium",
            else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          )
        ]}
      >
        {if @action && @action.type == :action, do: action_label(@action), else: "Actions"}
        <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
      </button>
      <div
        id="generic-actions-dropdown"
        class="hidden absolute left-0 top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"
        phx-click-away={JS.hide(to: "#generic-actions-dropdown")}
      >
        <.link
          :for={action <- @generic_actions}
          navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=action&action=#{action.name}&table=#{@table}"}
          class={[
            "block px-3 py-1.5 text-sm transition-colors",
            if(@action && @action.name == action.name && @action.type == :action,
              do: "bg-slate-100 dark:bg-slate-700 text-slate-900 dark:text-slate-100",
              else: "text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
            )
          ]}
        >
          {action_label(action)}
        </.link>
      </div>
    </div>
    """
  end

  defp create_action_button(assigns) do
    create_actions = get_create_actions(assigns.resource)
    assigns = assign(assigns, :create_actions, create_actions)

    ~H"""
    <%= case @create_actions do %>
      <% [] -> %>
      <% [single] -> %>
        <.link
          navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{single.name}&table=#{@table}"}
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 text-white dark:text-slate-900 transition-colors"
        >
          <AshAdmin.CoreComponents.icon name="hero-plus-mini" class="h-4 w-4" /> New
        </.link>
      <% actions -> %>
        <div class="relative">
          <button
            type="button"
            phx-click={JS.toggle(to: "#create-actions-dropdown")}
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-md bg-slate-800 hover:bg-slate-700 dark:bg-slate-200 dark:hover:bg-slate-300 text-white dark:text-slate-900 transition-colors"
          >
            <AshAdmin.CoreComponents.icon name="hero-plus-mini" class="h-4 w-4" /> New
            <AshAdmin.CoreComponents.icon name="hero-chevron-down-mini" class="h-4 w-4" />
          </button>
          <div
            id="create-actions-dropdown"
            class="hidden absolute right-0 top-full mt-1 w-48 bg-white dark:bg-slate-800 rounded-md shadow-lg ring-1 ring-slate-200 dark:ring-slate-700 py-1 z-30"
            phx-click-away={JS.hide(to: "#create-actions-dropdown")}
          >
            <.link
              :for={action <- actions}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{action.name}&table=#{@table}"}
              class="block px-3 py-1.5 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
            >
              {action_label(action)}
            </.link>
          </div>
        </div>
    <% end %>
    """
  end

  defp get_read_actions(resource) do
    read_actions = AshAdmin.Resource.read_actions(resource)

    resource
    |> Ash.Resource.Info.actions()
    |> Enum.filter(&(&1.type == :read && (is_nil(read_actions) || &1.name in read_actions)))
  end

  defp get_generic_actions(resource) do
    generic_actions = AshAdmin.Resource.generic_actions(resource)

    resource
    |> Ash.Resource.Info.actions()
    |> Enum.filter(
      &(&1.type == :action && (is_nil(generic_actions) || &1.name in generic_actions))
    )
  end

  defp get_create_actions(resource) do
    case AshAdmin.Resource.create_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.filter(&(&1.type == :create))

      [] ->
        []

      action_names ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.filter(&(&1.type == :create && &1.name in action_names))
    end
  end

  defp action_label(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
