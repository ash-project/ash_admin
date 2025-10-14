# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.DrawerDropdown do
  @moduledoc false
  use Phoenix.LiveComponent
  import AshAdmin.Helpers

  attr :name, :string, required: true
  attr :groups, :list, required: true
  attr :group_labels, :any, required: false

  def render(assigns) do
    ~H"""
    <div class="relative">
      <div>
        <a
          phx-click="toggle"
          phx-target={@myself}
          id={"#{@id}_dropdown_drawer"}
          href="#"
          class={
            classes(
              "mt-1 block px-3 py-2 rounded-t text-base font-medium text-gray-300 hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700":
                true,
              "text-white bg-gray-700": @open
            )
          }
        >
          {@name}
        </a>

        <div
          :for={group <- @groups}
          :if={@open}
          aria-labelledby={"#{@id}_dropown_drawer"}
          class="bg-gray-700 text-white"
          role="menu"
          aria-orientation="vertical"
          x-transition:enter="transition ease-out duration-150"
          x-transition:enter-start="opacity-0 transform -translate-y-3"
          x-transition:enter-end="opacity-100 transform translate-y-0"
          x-transition:leave="transition ease-in duration-150"
          x-transition:leave-end="opacity-0 transform -translate-y-3"
        >
          <.link
            :for={link <- group}
            navigate={link.to}
            class="block px-4 py-2 text-sm hover:bg-gray-200 hover:text-gray-900"
            role="menuitem"
          >
            {link.text}
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, :open, false)}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :open, !socket.assigns.open)}
  end
end
