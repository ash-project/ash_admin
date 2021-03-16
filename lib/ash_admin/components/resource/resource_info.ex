defmodule AshAdmin.Components.Resource.Info do
  use Surface.Component

  alias AshAdmin.Components.Resource.{RelationshipTable, AttributeTable}

  prop resource, :any, required: true
  prop api, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="relative mx-12">
      <AttributeTable resource={{ @resource }} />
      <RelationshipTable api={{ @api }} resource={{ @resource }} />
    </div>
    """
  end
end
