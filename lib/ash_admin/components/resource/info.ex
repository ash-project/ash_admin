defmodule AshAdmin.Components.Resource.Info do
  @moduledoc false
  use Surface.Component

  alias AshAdmin.Components.Resource.{RelationshipTable, AttributeTable, Source}

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(prefix, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="relative mx-12">
      <AttributeTable resource={@resource} />
      <RelationshipTable api={@api} resource={@resource} prefix={@prefix} />
      <Source resource={@resource} />
    </div>
    """
  end
end
