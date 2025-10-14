# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.Dropdown do
  @moduledoc false
  use Phoenix.LiveComponent
  import AshAdmin.Helpers

  attr :name, :string, required: true
  attr :groups, :list, required: true
  attr :group_labels, :any, required: false
  attr :active, :boolean, required: true
  attr :class, :string

  def render(assigns) do
    ~H"""
    <div class={classes(["relative", @class])} phx-target={@myself}>
      <div phx-target={@myself}>
        <button
          type="button"
          class={
            classes([
              "inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500",
              "bg-gray-800 hover:bg-gray-900 text-white": @active,
              "bg-white text-gray-700 hover:bg-gray-300": !@active
            ])
          }
          phx-click="toggle"
          phx-target={@myself}
          id={"#{@id}_dropdown_button"}
          aria-haspopup="true"
          aria-expanded="true"
        >
          {@name}

          <svg
            class="-mr-1 ml-2 h-5 w-5"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
              clip-rule="evenodd"
            />
          </svg>
        </button>

        <%= if @open do %>
          <div
            phx-click-away="close"
            class={
              classes([
                "origin-top-right absolute left-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 z-50",
                "bg-gray-600 hover:bg-gray-700": single_active_group?(@groups)
              ])
            }
            role="menu"
            aria-orientation="vertical"
            phx-target={@myself}
            id={"#{@id}_dropown"}
          >
            <%= for group when group != [] <- @groups do %>
              <div
                class="py-1"
                role="menu"
                aria-orientation="vertical"
                aria-labelledby={"#{@id}_dropown"}
              >
                <.group_label item={hd(group)} group_labels={@group_labels} />
                <%= for link <- group do %>
                  <.link
                    navigate={link.to}
                    class={
                      classes([
                        "block px-4 py-2 text-sm ",
                        "bg-gray-600 text-white hover:bg-gray-700": Map.get(link, :active),
                        "text-gray-700 hover:bg-gray-100 hover:text-gray-900": !Map.get(link, :active)
                      ])
                    }
                    role="menuotem"
                  >
                    {link.text}
                  </.link>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign(:open, false)
     |> assign_new(:class, fn -> "" end)
     |> assign_new(:group_labels, fn -> [] end)}
  end

  defp group_label(assigns) do
    assigns = Map.put(assigns, :label_text, group_label_text(assigns))

    ~H"""
    <%= if @label_text do %>
      <span class="block px-4 py-2 text-xs text-gray-400 font-semibold italic">
        {@label_text}
      </span>
    <% end %>
    """
  end

  # No labels specified for the whole dropdown
  defp group_label_text(assigns) when not is_map_key(assigns, :group_labels), do: nil
  defp group_label_text(%{group_labels: []}), do: nil

  # No label specified for this dropdown group
  defp group_label_text(%{item: item}) when not is_map_key(item, :group), do: nil

  # Maybe a label to display!
  defp group_label_text(assigns), do: Keyword.get(assigns.group_labels, assigns.item.group)

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :open, !socket.assigns.open)}
  end

  defp single_active_group?([[%{active: true}]]), do: true
  defp single_active_group?(_), do: false
end
