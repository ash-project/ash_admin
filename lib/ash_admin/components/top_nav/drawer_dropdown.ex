defmodule AshAdmin.Components.TopNav.DrawerDropdown do
  use Surface.Component

  alias Surface.Components.LiveRedirect

  prop(name, :string, required: true)
  prop(groups, :list, required: true)
  prop(id, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="relative">
      <div x-data="{isOpen: false}">
        <a
          @click="isOpen = !isOpen"
          id={{ "#{@id}_dropdown_drawer" }}
          class="mt-1 block px-3 py-2 rounded-t text-base font-medium text-gray-300 hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700"
          href="#"
          x-bind:class="{'text-white bg-gray-700': isOpen}"
        >
          {{ @name }}
        </a>

        <div
          :for={{ group <- @groups }}
          aria-labelledby={{ "#{@id}_dropown_drawer" }}
          class="bg-gray-700 text-white"
          x-show="isOpen"
          role="menu"
          aria-orientation="vertical"
          x-transition:enter="transition ease-out duration-150"
          x-transition:enter-start="opacity-0 transform -translate-y-3"
          x-transition:enter-end="opacity-100 transform translate-y-0"
          x-transition:leave="transition ease-in duration-150"
          x-transition:leave-end="opacity-0 transform -translate-y-3"
        >
          <LiveRedirect
            :for={{ link <- group }}
            to={{ link.to }}
            class="block px-4 py-2 text-sm hover:bg-gray-200 hover:text-gray-900"
            opts={{ role: "menuitem" }}
          >
            {{ link.text }}
          </LiveRedirect>
        </div>
      </div>
    </div>
    """
  end
end
