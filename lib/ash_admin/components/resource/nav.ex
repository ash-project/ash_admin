defmodule AshAdmin.Components.Resource.Nav do
  @moduledoc false
  use Surface.Component
  alias AshAdmin.Components.TopNav.Dropdown
  alias Surface.Components.LiveRedirect

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(tab, :string, required: true)
  prop(action, :any)
  prop(table, :any, default: nil)
  prop(prefix, :any, default: nil)

  def render(assigns) do
    ~F"""
    <nav class="bg-gray-800 w-full">
      <div class="px-4 sm:px-6 lg:px-8 w-full">
        <div class="flex items-center justify-between h-16 w-full">
          <div class="flex items-center w-full">
            <div class="flex-shrink-0">
              <h3 class="text-white text-lg">
                <LiveRedirect to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}"}>
                  {AshAdmin.Resource.name(@resource)}
                </LiveRedirect>
              </h3>
            </div>
            <div class="w-full">
              <div class="ml-12 flex items-center space-x-1">
                <div :if={has_create_action?(@resource)} class="relative">
                  <LiveRedirect
                    to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{create_action(@resource).name}&tab=create&table=#{@table}"}
                    class="inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500"
                  >
                    Create
                  </LiveRedirect>
                </div>

                <Dropdown
                  name="Read"
                  id={"#{@resource}_data_dropdown"}
                  active={@tab == "data"}
                  groups={data_groups(@prefix, @api, @resource, @action, @table)}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  defp create_action(resource) do
    AshAdmin.Helpers.primary_action(resource, :create) ||
      Enum.find(Ash.Resource.Info.actions(resource), &(&1.type == :create))
  end

  defp data_groups(prefix, api, resource, current_action, table) do
    read_actions = AshAdmin.Resource.read_actions(resource)

    [
      resource
      |> Ash.Resource.Info.actions()
      |> Enum.filter(&(&1.type == :read && (is_nil(read_actions) || &1.name in read_actions)))
      |> Enum.map(fn action ->
        %{
          text: action_name(action),
          to:
            "#{prefix}?api=#{AshAdmin.Api.name(api)}&resource=#{AshAdmin.Resource.name(resource)}&table=#{table}&action_type=read&action=#{action.name}",
          active: current_action == action
        }
      end)
    ]
  end

  defp has_create_action?(resource) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.any?(&(&1.type == :create))
  end

  defp action_name(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
