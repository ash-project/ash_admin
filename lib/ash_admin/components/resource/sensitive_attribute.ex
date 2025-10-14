# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.SensitiveAttribute do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.CoreComponents

  def mount(socket) do
    {:ok, assign(socket, viewed: false)}
  end

  def render(assigns) do
    assigns = assign(assigns, present?: assigns.value not in [nil, ""])

    ~H"""
    <div>
      <span :if={@present? && !@viewed} class="italic">
        --redacted--
        <span class="cursor-pointer" phx-click="toggle_sensitive_attribute" phx-target={@myself}>
          <.icon name="hero-eye-solid" class="w-5 h-5 text-gray-500" />
        </span>
      </span>
      <span :if={@present? && @viewed}>
        {render_slot(@inner_block)}
        <span class="cursor-pointer" phx-click="toggle_sensitive_attribute" phx-target={@myself}>
          <.icon name="hero-eye-slash-solid" class="w-5 h-5 text-gray-500" />
        </span>
      </span>
    </div>
    """
  end

  def handle_event("toggle_sensitive_attribute", _params, socket) do
    {:noreply, assign(socket, viewed: !socket.assigns.viewed)}
  end
end
