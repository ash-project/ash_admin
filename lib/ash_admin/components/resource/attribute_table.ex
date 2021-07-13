defmodule AshAdmin.Components.Resource.AttributeTable do
  @moduledoc false
  use Surface.Component

  prop(resource, :any, required: true)

  def render(assigns) do
    ~F"""
    <div :if={Enum.any?(attributes(@resource))}>
      <h1 class="text-center text-3xl rounded-t py-8">
        Attributes
      </h1>
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th scope="col" class="text-center">Name</th>
            <th scope="col" class="text-center">Type</th>
            <th scope="col" class="text-center">Description</th>
            <th scope="col" class="text-center">Primary Key</th>
            <th scope="col" class="text-center">Private</th>
            <th scope="col" class="text-center">Allow Nil</th>
            <th scope="col" class="text-center">Writable</th>
          </tr>
        </thead>
        <tbody>
          <tr
            class={"h-10", "bg-gray-200": rem(index, 2) == 0}
            :for.with_index={{attribute, index} <- attributes(@resource)}
          >
            <th scope="row" class="text-center px-3">
              {attribute.name}
            </th>
            <td class="text-center px-3">
              {attribute_type(attribute)}
            </td>
            <td class="text-center max-w-sm min-w-sm">{attribute.description}</td>
            <td class="text-center">{to_string(attribute.primary_key?)}</td>
            <td class="text-center">{to_string(attribute.private?)}</td>
            <td class="text-center">{to_string(attribute.allow_nil?)}</td>
            <td class="text-center">{to_string(attribute.writable?)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp attributes(resource) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.sort_by(& &1.private?)
  end

  defp attribute_type(attribute) do
    case attribute.type do
      {:array, type} ->
        "list of " <> String.trim_leading(inspect(type), "Ash.Type.")

      type ->
        String.trim_leading(inspect(type), "Ash.Type.")
    end
  end
end
