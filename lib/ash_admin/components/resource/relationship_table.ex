defmodule AshAdmin.Components.Resource.RelationshipTable do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(prefix, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="w-full" :if={Enum.any?(relationships(@resource))}>
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
            class={"h-10", "bg-gray-200": rem(index, 2) == 0}
            :for.with_index={{relationship, index} <- relationships(@resource)}
          >
            <th scope="row">
              {relationship.name}
            </th>
            <td class="text-left">
              {relationship.type}</td>
            <td class="text-left">
              <LiveRedirect to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(relationship.destination)}"}>
                {AshAdmin.Resource.name(relationship.destination)}
              </LiveRedirect>
            </td>
            <td class="text-left max-w-sm min-w-sm">{relationship.description}</td>
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
