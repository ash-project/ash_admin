defmodule AshAdmin.Components.Resource.SelectTable do
  use Surface.Component

  alias Surface.Components.Form
  alias Surface.Components.Form.{FieldContext, Label, Select}

  prop(resource, :any, required: true)
  prop(on_change, :event, required: true)
  prop(table, :any, required: true)
  prop(tables, :any, required: true)

  def render(assigns) do
    ~H"""
    <div>
      <div :if={{ @resource && AshAdmin.Resource.polymorphic?(@resource) }}>
        <Form as="table" for={{ :table }} change={{ @on_change }}>
          <FieldContext name="table">
            <Label>Table</Label>
            <Select selected={{ @table }} options={{ @tables || [] }} />
          </FieldContext>
        </Form>
      </div>
    </div>
    """
  end
end
