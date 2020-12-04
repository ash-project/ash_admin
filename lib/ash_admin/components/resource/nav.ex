defmodule AshAdmin.Components.Resource.Nav do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  import AshAdmin.Helpers

  prop resource, :any, required: true
  prop api, :any, required: true
  prop tab, :string, required: true
  prop action, :any

  def render(assigns) do
    ~H"""
    <nav class="navbar navbar-expand navbar-light bg-light" style="margin-bottom: 20px;">
      <span class="navbar-brand" href="#"> {{ AshAdmin.Resource.name(@resource) }}</span>
      <ul class="navbar-nav mr-auto" style="overflow-y: visible;">
        <li class={{"nav-item", active: @tab == "info"}}>
          <LiveRedirect class="nav-link" to={{ash_admin_path(@socket, @api, @resource)}}>Info</LiveRedirect>
        </li>
        <li class="nav-item dropdown">
          <a class={{"nav-link", "dropdown-toggle", active: @action && @action.type == :read}} href="#" id="dataDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            Data
          </a>
          <div class="dropdown-menu" aria-labelledby="dataDropdown">
            <a :if={{ has_create_action?(@resource) }} href="#" class="dropdown-item">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-plus-circle"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>
              Create
            </a>
            <div :if={{ has_create_action?(@resource) }} class="dropdown-divider"></div>
            <LiveRedirect
              :for={{ action <- read_actions(@resource) }}
              to={{ash_action_path(@socket, @api, @resource, action.type, action.name)}}
              class={{ "dropdown-item", active: action_active?(action, @action) }}
              opts={{[id: "read-#{action.name}", "aria-selected": to_string(action_active?(action, @action))]}}>
              {{ action_name(action) }}
            </LiveRedirect>
          </div>
        </li>
      </ul>
    </nav>
    """
  end

  defp has_create_action?(resource) do
    resource
    |> Ash.Resource.actions()
    |> Enum.any?(&(&1.type == :create))
  end

  defp action_name(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp action_active?(_, nil), do: false
  defp action_active?(%{type: type, name: name}, %{type: type, name: name}), do: true
  defp action_active?(_, _), do: false

  defp read_actions(resource) do
    resource
    |> Ash.Resource.actions()
    |> Enum.filter(&(&1.type == :read))
  end
end
