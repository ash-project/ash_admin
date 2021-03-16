defmodule AshAdmin.Components.Resource.Show do
  use Surface.Component

  alias Surface.Components.LiveRedirect
  import AshAdmin.Helpers

  prop(resource, :any)
  prop(record, :any, default: nil)
  prop(api, :any, default: nil)
  prop action, :any

  # data(query, :any)

  # def update(assigns, socket) do
  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign(:initialized, true)
  #    |> assign(:arguments, nil)
  #    |> assign_query()}
  # end

  # defp assign_query(socket) do
  #   query =
  #     socket.assigns.resource
  #     |> Ash.Query.for_read(socket.assigns.action.name,
  #       actor: socket.assigns[:actor],
  #       tenant: socket.assigns[:tenant]
  #     )
  #     |> AshPhoenix.hide_errors()

  #   assign(socket, :query, query)
  # end

  def render(assigns) do
    ~H"""
    <div class="mt-10 sm:mt-0">
      <div class="md:grid md:grid-cols-3 md:gap-6 mx-16 mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          <div class="shadow overflow-hidden sm:rounded-md">
            <div class="px-4 py-5 bg-white sm:p-6">
              {{{attributes, flags, bottom_attributes} = AshAdmin.Components.Resource.Form.attributes(@resource, :show); nil}}
              <div class="grid grid-cols-6 gap-6">
                <div :for={{attribute <- attributes}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                  <dt class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</dt>
                  <dd>{{Map.get(@record, attribute.name)}}</dd>
                </div>
              </div>
              <div :if={{!Enum.empty?(flags)}} class="hidden sm:block" aria-hidden="true">
                <div class="py-5">
                  <div class="border-t border-gray-200"></div>
                </div>
              </div>
              <div class="grid grid-cols-6 gap-6" :if={{!Enum.empty?(bottom_attributes)}}>
                <div :for={{attribute <- flags}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                  <dt class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</dt>
                  <dd>{{Map.get(@record, attribute.name)}}</dd>
                </div>
              </div>
              <div :if={{!Enum.empty?(bottom_attributes)}} class="hidden sm:block" aria-hidden="true">
                <div class="py-5">
                  <div class="border-t border-gray-200"></div>
                </div>
              </div>
              <div class="grid grid-cols-6 gap-6" :if={{!Enum.empty?(bottom_attributes)}}>
                <div :for={{attribute <- bottom_attributes}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                  <dt class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</dt>
                  <dd>{{Map.get(@record, attribute.name)}}</dd>
                </div>
              </div>
            </div>

            <LiveRedirect to={{ash_update_path(@socket, @api, @resource, @record)}} :if={{update?(@resource)}} class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 mb-4 ml-4">
              Update
            </LiveRedirect>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # def handle_event("validate", %{"query" => data}, socket) do
  #   query =
  #     Ash.Query.for_read(socket.assigns.resource, socket.assigns.action.name, data,
  #       actor: socket.assigns[:actor],
  #       tenant: socket.assigns[:tenant]
  #     )

  #   {:noreply, assign(socket, query: query)}
  # end

  # def handle_event("save", %{"query" => data}, socket) do
  #   socket.assigns.resource
  #   |> Ash.Query.for_read(socket.assigns.action.name, data,
  #     actor: socket.assigns[:actor],
  #     tenant: socket.assigns[:tenant]
  #   )
  #   |> socket.assigns.api.read_one()
  #   |> case do
  #     {:ok, value} ->
  #       {:noreply,
  #        socket
  #        |> assign(record: value)
  #        |> push_patch(to: self_path(socket.assigns.uri, socket.assigns.params, data))}

  #     {:error, %{query: query}} ->
  #       {:noreply, assign(socket, query: query)}
  #   end
  # end

  defp short_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :short_text} ->
        true

      _ ->
        false
    end
  end

  defp long_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :long_text} ->
        true

      _ ->
        false
    end
  end

  defp update?(resource) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.any?(&(&1.type == :update))
  end
end
