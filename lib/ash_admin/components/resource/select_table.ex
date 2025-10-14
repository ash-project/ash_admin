# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.SelectTable do
  @moduledoc false
  use Phoenix.Component
  import AshAdmin.CoreComponents

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
          <.input type="select" field={form[:table]} options={@tables} />
        </.form>
      </div>
    </div>
    """
  end
end
