defmodule AshAdmin.Components.Resource.AttributeTable do
  @moduledoc false
  use Phoenix.Component
  import Tails

  alias AshAdmin.Components.HeroIcon

  attr :resource, :any, required: true

  def table(assigns) do
    ~H"""
    <div :if={Enum.any?(attributes(@resource))}>
      <h1 class="text-3xl rounded-t py-8">
        Attributes
      </h1>
      <table class="table-auto w-full">
        <thead>
          <tr>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">Name</th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">Type</th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              Description
            </th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              Primary Key
            </th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              Private
            </th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              Allow Nil
            </th>
            <th scope="col" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              Writable
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{attribute, index} <- Enum.with_index(attributes(@resource))}
            class={classes(["h-10", "bg-gray-200": rem(index, 2) == 0])}
          >
            <th scope="row" class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              <%= attribute.name %>
            </th>
            <td class="px-2 py-3 text-left text-sm text-gray-900">
              <%= attribute_type(attribute) %>
            </td>
            <td class="max-w-sm min-w-sm text-sm text-gray-500"><%= attribute.description %></td>
            <td class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              <HeroIcon.icon
                name={if attribute.primary_key?, do: "check", else: "x"}
                class="h-4 w-4 text-gray-500"
              />
            </td>
            <td class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              <HeroIcon.icon
                name={if attribute.private?, do: "check", else: "x"}
                class="h-4 w-4 text-gray-500"
              />
            </td>
            <td class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              <HeroIcon.icon
                name={if attribute.allow_nil?, do: "check", else: "x"}
                class="h-4 w-4 text-gray-500"
              />
            </td>
            <td class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
              <HeroIcon.icon
                name={if attribute.writable?, do: "check", else: "x"}
                class="h-4 w-4 text-gray-500"
              />
            </td>
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
