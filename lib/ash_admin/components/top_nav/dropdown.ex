defmodule AshAdmin.Components.TopNav.Dropdown do
  use Surface.Component

  alias Surface.Components.LiveRedirect

  prop name, :string, required: true
  prop groups, :list, required: true
  prop id, :string, required: true
  prop active, :boolean, required: true

  def render(assigns) do
    ~H"""
    <div class="relative">
      <div x-data="{isOpen: false}" class="mx-2">
        <button
        type="button"
        class={{"inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500", "bg-gray-800 hover:bg-gray-900 text-white": @active, "bg-white text-gray-700 hover:bg-gray-300": !@active}}
        @click="isOpen = !isOpen"
        id={{"#{@id}_dropown"}}
        aria-haspopup="true"
        aria-expanded="true">
          {{@name}}
          <!-- Heroicon name: chevron-down -->
          <svg class="-mr-1 ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>

        <div
          x-show="isOpen"
          class={{"origin-top-right absolute left-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 z-10", "bg-gray-600 hover:bg-gray-700": single_active_group?(@groups)}}
          x-transition:enter="transition ease-out duration-100"
          x-transition:enter-start="transform opacity-0 scale-95"
          x-transition:enter-end="transform opacity-0 scale-95"
          x-transition:leave="transition ease-in duration-75"
          x-transition:leave-start="transform opacity-100 scale-100"
          x-transition:leave-end="transform opacity-0 scale-95"
          role="menu"
          aria-orientation="vertical"
          @click.away="isOpen=false"
          id={{"#{@id}_dropown"}}>
          <div
            :for={{ group <- @groups }}
            class="py-1"
            role="menu"
            aria-orientation="vertical"
            aria-labelledby={{"#{@id}_dropown"}}>
            <LiveRedirect
            :for={{ link <- group }}
            to={{ link.to }}
            class={{"block px-4 py-2 text-sm ", "bg-gray-600 text-white hover:bg-gray-700": Map.get(link, :active), "text-gray-700 hover:bg-gray-100 hover:text-gray-900": !Map.get(link, :active)}}
            opts={{role: "menuitem"}}>
              {{link.text}}
            </LiveRedirect>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp single_active_group?([[%{active: true}]]), do: true
  defp single_active_group?(_), do: false
end
