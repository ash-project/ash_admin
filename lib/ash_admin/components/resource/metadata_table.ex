defmodule AshAdmin.Components.Resource.MetadataTable do
  @moduledoc false
  use Phoenix.Component
  import AshAdmin.Helpers

  alias AshAdmin.CoreComponents

  attr :resource, :any, required: true

  def attribute_table(assigns) do
    ~H"""
    <div :if={Enum.any?(attributes(@resource))}>
      <.h1>Attributes</.h1>
      <.table>
        <thead>
          <tr>
            <.th>Name</.th>
            <.th>Type</.th>
            <.th>Description</.th>
            <.th>Primary Key</.th>
            <.th>Private</.th>
            <.th>Allow Nil</.th>
            <.th>Writable</.th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{attribute, index} <- Enum.with_index(attributes(@resource))}
            class={classes("bg-gray-200": rem(index, 2) == 0)}
          >
            <.th scope="row">
              {attribute.name}
            </.th>
            <.td>
              {attribute_type(attribute)}
            </.td>
            <.td class="max-w-sm min-w-sm text-gray-500">
              {attribute.description}
            </.td>
            <.td>
              <CoreComponents.icon
                name={if attribute.primary_key?, do: "hero-check", else: "hero-x-mark"}
                class="h-4 w-4 text-gray-500"
              />
            </.td>
            <.td>
              <CoreComponents.icon
                name={if !attribute.public?, do: "hero-check", else: "hero-x-mark"}
                class="h-4 w-4 text-gray-500"
              />
            </.td>
            <.td>
              <CoreComponents.icon
                name={if attribute.allow_nil?, do: "hero-check", else: "hero-x-mark"}
                class="h-4 w-4 text-gray-500"
              />
            </.td>
            <.td>
              <CoreComponents.icon
                name={if attribute.writable?, do: "hero-check", else: "hero-x-mark"}
                class="h-4 w-4 text-gray-500"
              />
            </.td>
          </tr>
        </tbody>
      </.table>
    </div>
    """
  end

  attr :resource, :any, required: true
  attr :domain, :any, required: true
  attr :prefix, :any, required: true
  attr :current_group, :any, default: nil

  def relationship_table(assigns) do
    ~H"""
    <div :if={Enum.any?(relationships(@resource))} class="w-full">
      <.h1>Relationships</.h1>

      <.table>
        <thead>
          <tr>
            <.th>Name</.th>
            <.th>Type</.th>
            <.th>Destination</.th>
            <.th>Description</.th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={{relationship, index} <- Enum.with_index(relationships(@resource))}
            class={classes("bg-gray-200": rem(index, 2) == 0)}
          >
            <.th scope="row">
              {relationship.name}
            </.th>
            <.td>
              {relationship.type}
            </.td>
            <.td>
              <%=  %>
              <%= if destination_domain_accessible?(relationship, @domain, @current_group) do %>
                <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(destination_domain(relationship, @domain))}&resource=#{AshAdmin.Resource.name(relationship.destination)}"}>
                  {AshAdmin.Resource.name(relationship.destination)}
                </.link>
              <% else %>
                <span class="text-gray-400">
                  {AshAdmin.Resource.name(relationship.destination)} (not accessible)
                </span>
              <% end %>
            </.td>
            <.td class="max-w-sm min-w-sm text-gray-500">
              {relationship.description}
            </.td>
          </tr>
        </tbody>
      </.table>
    </div>
    """
  end

  slot :inner_block

  def h1(assigns) do
    ~H"""
    <h1 class="text-3xl rounded-t py-8">
      {render_slot(@inner_block)}
    </h1>
    """
  end

  slot :inner_block

  def table(assigns) do
    ~H"""
    <table class="table-auto w-full">
      {render_slot(@inner_block)}
    </table>
    """
  end

  attr :scope, :string, default: "col"
  slot :inner_block

  def th(assigns) do
    ~H"""
    <th scope={@scope} class="px-2 py-3 text-left text-sm font-semibold text-gray-900">
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :class, :string, default: ""
  slot :inner_block

  def td(assigns) do
    ~H"""
    <td class={classes(["px-2 py-3 text-left text-sm text-gray-900", @class])}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  defp attributes(resource) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.sort_by(&(not &1.public?))
  end

  defp attribute_type(attribute) do
    case attribute.type do
      {:array, type} ->
        "list of " <> String.trim_leading(inspect(type), "Ash.Type.")

      type ->
        String.trim_leading(inspect(type), "Ash.Type.")
    end
  end

  defp relationships(resource) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.sort_by(&(not &1.public?))
  end

  defp destination_domain(relationship, fallback \\ nil) do
    Ash.Resource.Info.domain(relationship.destination) || fallback
  end

  defp destination_domain_accessible?(relationship, domain, current_group) do
    # Get the destination domain of the relationship
    destination_domain = destination_domain(relationship, domain)

    # Use the helper function from AshAdmin.Domain to check accessibility
    AshAdmin.Domain.domain_accessible_in_group?(destination_domain, current_group)
  end
end
