defmodule AshAdmin.Components.Resource.Info do
  @moduledoc false
  use Surface.Component

  alias AshAdmin.Components.Resource.{RelationshipTable, AttributeTable}

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(prefix, :any, required: true)

  def render(assigns) do
    ~H"""
    <div class="relative mx-12">
      <AttributeTable resource={{ @resource }} />
      <RelationshipTable api={{ @api }} resource={{ @resource }} prefix={{ @prefix }} />
    </div>
    """
  end
end
