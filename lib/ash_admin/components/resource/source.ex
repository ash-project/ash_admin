defmodule AshAdmin.Components.Resource.Source do
  @moduledoc false
  use Surface.Component

  prop(resource, :any, required: true)

  def render(assigns) do
    ~F"""
    {inspect(File.read!(@resource.module_info(:compile)[:source]))}
    """
  end
end
