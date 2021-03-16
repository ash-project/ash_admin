defmodule AshAdmin.Components.Resource.RelationshipTable do
  use Surface.Component
  import AshAdmin.Helpers
  alias Surface.Components.LiveRedirect

  prop(resource, :any, required: true)
  prop(api, :any, required: true)

  def render(assigns) do
    ~H"""
    <div class="w-full" :if={{ Enum.any?(relationships(@resource)) }}>
      <h1 class="text-center text-3xl rounded-t py-8">
        Relationships
      </h1>
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th scope="col" class="text-center">Name</th>
            <th scope="col" class="text-center">Type</th>
            <th scope="col" class="text-center">Destination</th>
            <th scope="col" class="text-center">Description</th>
          </tr>
        </thead>
        <tbody>
          <tr
            class={{ "h-10", "bg-gray-200": rem(index, 2) == 0 }}
            :for.with_index={{ {relationship, index} <- relationships(@resource) }}
          >
            <th scope="row">
              {{ relationship.name }}
            </th>
            <td class="text-center">
              {{ relationship.type }}</td>
            <td class="text-center">
              <LiveRedirect to={{ ash_admin_path(@socket, @api, relationship.destination) }}>
                {{ AshAdmin.Resource.name(relationship.destination) }}
              </LiveRedirect>
            </td>
            <td class="text-center max-w-sm min-w-sm">{{ relationship.description }}</td>
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
