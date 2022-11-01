defmodule AshAdmin.Components.Resource.SelectTable do
  @moduledoc false
  use Surface.Component

  alias Surface.Components.Form
  alias Surface.Components.Form.{FieldContext, Label, Select}

  prop(resource, :any, required: true)
  prop(on_change, :event, required: true)
  prop(table, :any, required: true)
  prop(tables, :any, required: true)
  prop(action, :any, required: true)
  prop(polymorphic_actions, :any, required: true)

  def render(assigns) do
    ~F"""
    <div>
      <div :if={@resource && @tables != [] &&
        (is_nil(@polymorphic_actions) || @action.name in @polymorphic_actions)}>
        <Form as={:table} for={:table} change={@on_change}>
          <FieldContext name="table">
            <Label>Table</Label>
            <Select selected={@table} options={@tables || []} />
          </FieldContext>
        </Form>
      </div>
    </div>
    """
  end
end
