defmodule AshAdmin.Components.Resource.Info do
  @moduledoc false
  use Phoenix.Component

  alias AshAdmin.Components.Resource.{AttributeTable, RelationshipTable}

  attr :resource, :any, required: true
  attr :api, :any, required: true
  attr :prefix, :any, required: true

  def info(assigns) do
    ~H"""
    <div class="relative mx-12">
      <AttributeTable.table resource={@resource} />
      <RelationshipTable.table api={@api} resource={@resource} prefix={@prefix} />
    </div>
    """
  end
end
