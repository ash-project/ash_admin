defmodule AshAdmin.Components.Resource.SelectTable do
  @moduledoc false
  use Phoenix.Component

  attr :resource, :any, required: true
  attr :on_change, :string, required: true
  attr :table, :any, required: true
  attr :tables, :any, required: true
  attr :action, :any, required: true
  attr :target, :any, required: true
  attr :polymorphic_actions, :any, required: true

  def table(assigns) do
    ~H"""
    <div>
      <div :if={
        @resource && @tables != [] &&
          (is_nil(@polymorphic_actions) || @action.name in @polymorphic_actions)
      }>
        <.form :let={form} for={to_form(%{}, as: :table)} phx-change={@on_change} phx-target={@target}>
          <%= Phoenix.HTML.Form.select(form, :table, @tables) %>
        </.form>
      </div>
    </div>
    """
  end
end
