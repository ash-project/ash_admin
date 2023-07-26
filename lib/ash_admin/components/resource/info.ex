defmodule AshAdmin.Components.Resource.Info do
  @moduledoc false
  use Phoenix.Component

  alias AshAdmin.Components.Resource.MetadataTable

  attr :resource, :any, required: true
  attr :api, :any, required: true
  attr :prefix, :any, required: true

  def info(assigns) do
    ~H"""
    <div class="relative mx-12">
      <MetadataTable.attribute_table resource={@resource} />
      <MetadataTable.relationship_table api={@api} resource={@resource} prefix={@prefix} />
    </div>
    """
  end
end
