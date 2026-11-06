# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
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
    revealable? = AshAdmin.reveal_sensitive_fields?()

    assigns =
      assign(assigns,
        present?: assigns.value not in [nil, ""],
        revealable?: revealable?,
        revealed?: revealable? && assigns.viewed
      )

    ~H"""
    <div>
      <span :if={@present? && !@revealed?} class="italic">
        --redacted--
        <span
          :if={@revealable?}
          class="cursor-pointer"
          phx-click="toggle_sensitive_attribute"
          phx-target={@myself}
        >
          <.icon name="hero-eye-solid" class="w-5 h-5 text-slate-500 dark:text-slate-400" />
        </span>
      </span>
      <span :if={@present? && @revealed?}>
        {render_slot(@inner_block)}
        <span class="cursor-pointer" phx-click="toggle_sensitive_attribute" phx-target={@myself}>
          <.icon name="hero-eye-slash-solid" class="w-5 h-5 text-slate-500 dark:text-slate-400" />
        </span>
      </span>
    </div>
    """
  end

  # The event can be sent without the icon, so it is refused here, not only hidden.
  def handle_event("toggle_sensitive_attribute", _params, socket) do
    if AshAdmin.reveal_sensitive_fields?() do
      {:noreply, assign(socket, viewed: !socket.assigns.viewed)}
    else
      {:noreply, socket}
    end
  end
end
