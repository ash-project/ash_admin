defmodule AshAdmin.Components.Resource.RelationshipTable do
  @moduledoc false
  use Phoenix.Component
  import Tails

  attr :resource, :any, required: true
  attr :api, :any, required: true
  attr :prefix, :any, required: true

  def table(assigns) do
    ~H"""
    <div :if={Enum.any?(relationships(@resource))} class="w-full">
      <h1 class="text-left text-3xl rounded-t py-8">
        Relationships
      </h1>
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th scope="col" class="text-left">Name</th>
            <th scope="col" class="text-left">Type</th>
            <th scope="col" class="text-left">Destination</th>
            <th scope="col" class="text-left">Description</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{relationship, index} <- Enum.with_index(relationships(@resource))}
            class={classes(["h-10", "bg-gray-200": rem(index, 2) == 0])}
          >
            <th scope="row">
              <%= relationship.name %>
            </th>
            <td class="text-left">
              <%= relationship.type %>
            </td>
            <td class="text-left">
              <.link navigate={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(relationship.destination)}"}>
                <%= AshAdmin.Resource.name(relationship.destination) %>
              </.link>
            </td>
            <td class="text-left max-w-sm min-w-sm"><%= relationship.description %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp relationships(resource) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.sort_by(& &1.private?)
  end
end
