# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Nav do
  @moduledoc false
  use Phoenix.Component
  alias AshAdmin.Components.TopNav.Dropdown
  import AshAdmin.Helpers

  attr :resource, :any, required: true
  attr :domain, :any, required: true
  attr :action, :any
  attr :table, :any, default: nil
  attr :prefix, :any, default: nil

  def nav(assigns) do
    ~H"""
    <nav class="bg-gray-800 w-full">
      <div class="px-4 sm:px-6 lg:px-8 w-full">
        <div class="flex items-center justify-between h-16 w-full">
          <div class="flex items-center w-full">
            <div class="flex-shrink-0">
              <h3 class="text-white text-lg">
                <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}"}>
                  {AshAdmin.Resource.name(@resource)}
                </.link>
              </h3>
            </div>
            <div class="w-full">
              <div class="ml-12 flex items-center space-x-1">
                <div :if={has_create_action?(@resource)} class="relative">
                  <.link
                    navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=create&action=#{create_action(@resource).name}&table=#{@table}"}
                    class={
                      classes([
                        "inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500",
                        "bg-gray-800 hover:bg-gray-900 text-white":
                          @action && @action.type == :create,
                        "bg-white text-gray-700 hover:bg-gray-300":
                          !@action || @action.type != :create
                      ])
                    }
                  >
                    Create
                  </.link>
                </div>

                <.live_component
                  module={Dropdown}
                  name={tab_name(@action && @action.name, @action && @action.type == :read, "Read")}
                  id={"#{@resource}_data_dropdown"}
                  active={@action && @action.type == :read}
                  groups={data_groups(@prefix, @domain, @resource, @action, @table)}
                />

                <%= case action_groups(@prefix, @domain, @resource, @action, @table) do %>
                  <% [[]] -> %>
                  <% groups -> %>
                    <.live_component
                      module={Dropdown}
                      name={
                        tab_name(
                          @action && @action.name,
                          @action && @action.type == :action,
                          "Actions"
                        )
                      }
                      id={"#{@resource}_actions_dropdown"}
                      active={@action && @action.type == :action}
                      groups={groups}
                    />
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  defp tab_name(label, true, _) when not is_nil(label) and label != false do
    Phoenix.Naming.humanize(label)
  end

  defp tab_name(_, _, default) do
    default
  end

  defp create_action(resource) do
    case AshAdmin.Helpers.primary_action(resource, :create) ||
           Enum.find(Ash.Resource.Info.actions(resource), &(&1.type == :create)) do
      nil ->
        nil

      primary_action ->
        case AshAdmin.Resource.create_actions(resource) do
          nil ->
            primary_action

          list ->
            if primary_action.name in list do
              primary_action
            else
              case Enum.at(list, 0) do
                nil -> nil
                action -> Ash.Resource.Info.action(resource, action)
              end
            end
        end
    end
  end

  defp data_groups(prefix, domain, resource, current_action, table) do
    read_actions = AshAdmin.Resource.read_actions(resource)

    [
      resource
      |> Ash.Resource.Info.actions()
      |> Enum.filter(&(&1.type == :read && (is_nil(read_actions) || &1.name in read_actions)))
      |> Enum.map(fn action ->
        %{
          text: action_name(action),
          to:
            "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}&table=#{table}&action_type=read&action=#{action.name}",
          active: current_action == action
        }
      end)
    ]
  end

  defp action_groups(prefix, domain, resource, current_action, table) do
    generic_actions = AshAdmin.Resource.generic_actions(resource)

    [
      resource
      |> Ash.Resource.Info.actions()
      |> Enum.filter(
        &(&1.type == :action && (is_nil(generic_actions) || &1.name in generic_actions))
      )
      |> Enum.map(fn action ->
        %{
          text: action_name(action),
          to:
            "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}&table=#{table}&action_type=action&action=#{action.name}",
          active: current_action == action
        }
      end)
    ]
  end

  defp has_create_action?(resource) do
    case AshAdmin.Resource.create_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.any?(&(&1.type == :create))

      [] ->
        false

      _ ->
        true
    end
  end

  defp action_name(action) do
    action.name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
