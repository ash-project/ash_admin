defmodule AshAdmin.Components.Resource.Nav do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias AshAdmin.Components.TopNav.Dropdown
  import AshAdmin.Helpers

  prop resource, :any, required: true
  prop api, :any, required: true
  prop tab, :string, required: true
  prop action, :any

  def render(assigns) do
    ~H"""
    <nav class="bg-gray-800 w-full">
      <div class="px-4 sm:px-6 lg:px-8 w-full">
        <div class="flex items-center justify-between h-16 w-full">
          <div class="flex items-center w-full">
            <div class="flex-shrink-0">
              <h3 class="text-white text-lg ">
                <LiveRedirect to={{ash_admin_path(@socket, @api, @resource)}}>
                  {{AshAdmin.Resource.name(@resource)}}
                </LiveRedirect>
              </h3>
            </div>
            <div class="w-full">
              <div class="ml-12 flex items-center">
                <div :if={{has_create_action?(@resource)}} class="relative">
                  <LiveRedirect
                    to={{ash_create_path(@socket, @api, @resource)}}
                    class="inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500">
                  Create
                  </LiveRedirect>
                </div>
                <Dropdown name="Read" id={{"#{@resource}_data_dropdown"}} active={{@tab == "data"}} groups={{data_groups(@socket, @api, @resource, @action)}} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  defp data_groups(socket, api, resource, current_action) do
    [
      resource
      |> Ash.Resource.actions()
      |> Enum.filter(&(&1.type == :read))
      |> Enum.map(fn action ->
        %{
          text: action_name(action),
          to: ash_action_path(socket, api, resource, :read, action.name),
          active: current_action == action
        }
      end)
    ]
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
end
