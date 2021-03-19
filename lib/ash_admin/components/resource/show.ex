defmodule AshAdmin.Components.Resource.Show do
  use Surface.Component

  alias Surface.Components.LiveRedirect
  import AshAdmin.Helpers

  prop(resource, :any)
  prop(record, :any, default: nil)
  prop(api, :any, default: nil)
  prop(action, :any)

  def render(assigns) do
    ~H"""
    <div class="pt-10 sm:mt-0 bg-gray-300 min-h-screen">
      <div class="md:grid md:grid-cols-3 md:gap-6 mx-16 mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {{ render_show(assigns, @record, @resource) }}
        </div>
      </div>
    </div>
    """
  end

  defp render_show(assigns, record, resource) do
    ~H"""
    <div class="shadow-lg overflow-hidden sm:rounded-md bg-white">
      <div class="px-4 py-5 sm:p-6">
        <div>
          {{ render_attributes(assigns, record, resource) }}
          <div class="px-4 py-3 text-right sm:px-6">
            <LiveRedirect
              to={{ ash_update_path(@socket, @api, @resource, @record) }}
              :if={{ update?(@resource) }}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Update
            </LiveRedirect>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_attributes(assigns, record, resource) do
    ~H"""
    {{ {attributes, flags, bottom_attributes} =
      AshAdmin.Components.Resource.Form.attributes(resource, :show)

    nil }}
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={{ attribute <- attributes }}
        class={{
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !long_text?(resource, attribute)
        }}
      >
        <div class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</div>
        <div>{{ render_attribute(assigns, resource, record, attribute) }}</div>
      </div>
    </div>
    <div :if={{ !Enum.empty?(flags) }} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div class="grid grid-cols-6 gap-6" :if={{ !Enum.empty?(flags) }}>
      <div
        :for={{ attribute <- flags }}
        class={{
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !long_text?(resource, attribute)
        }}
      >
        <div class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</div>
        <div>{{ render_attribute(assigns, resource, record, attribute) }}</div>
      </div>
    </div>
    <div :if={{ !Enum.empty?(bottom_attributes) }} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div class="grid grid-cols-6 gap-6" :if={{ !Enum.empty?(bottom_attributes) }}>
      <div
        :for={{ attribute <- bottom_attributes }}
        class={{
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !(long_text?(resource, attribute) || Ash.Type.embedded_type?(attribute.type))
        }}
      >
        <div class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</div>
        <div>{{ render_attribute(assigns, resource, record, attribute) }}</div>
      </div>
    </div>
    """
  end

  defp render_attribute(assigns, resource, record, attribute, nested? \\ false)

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, type}, name: name} = attribute,
         nested?
       ) do
    all_classes = "mb-4 pb-4 shadow-md"

    if Map.get(record, name) in [[], nil] do
      ~H"""
      None
      """
    else
      if nested? do
        ~H"""
        <ul>
          <li :for={{ value <- List.wrap(Map.get(record, name)) }} class={{all_classes}}>
            {{ render_attribute(assigns, resource, Map.put(record, name, value), %{attribute | type: type}, true) }}
          </li>
        </ul>
        """
      else
        ~H"""
        <div class="shadow-md border mt-4 mb-4 ml-4">
          <ul>
            <li :for={{ value <- List.wrap(Map.get(record, name)) }} class={{"my-4", all_classes}}>
              {{ render_attribute(assigns, resource, Map.put(record, name, value), %{attribute | type: type}, true) }}
            </li>
          </ul>
        </div>
        """
      end
    end
  end

  defp render_attribute(assigns, resource, record, %{name: name, type: Ash.Type.Boolean}, _) do
    case Map.get(record, name) do
      true ->
        ~H"""
        {{ {:safe, Heroicons.Solid.check(class: "text-gray-600 h-4 w-4")} }}
        """

      false ->
        ~H"""
        {{ {:safe, Heroicons.Solid.x(class: "text-gray-600 h-4 w-4")} }}
        """

      nil ->
        ~H"""
        {{ {:safe, Heroicons.Solid.minus(class: "text-gray-600 h-4 w-4")} }}
        """
    end
  end

  defp render_attribute(assigns, resource, record, attribute, nested?) do
    if Ash.Type.embedded_type?(attribute.type) do
      both_classes = "ml-1 pl-2 pr-2"

      if Map.get(record, attribute.name) in [nil, []] do
        ~H"""
        None
        """
      else
        if nested? do
          ~H"""
          <div class={{both_classes}}>
          {{ render_attributes(assigns, Map.get(record, attribute.name), attribute.type) }}
          </div>
          """
        else
          ~H"""
          <div class={{"shadow-md border mt-4 mb-4 ml-2 rounded py-2 px-2", both_classes}}>
            {{ render_attributes(assigns, Map.get(record, attribute.name), attribute.type) }}
          </div>
          """
        end
      end
    else
      if attribute.type == Ash.Type.String do
        cond do
          short_text?(resource, attribute) ->
            ~H"""
            {{ value!(Map.get(record, attribute.name)) }}
            """

          long_text?(resource, attribute) ->
            ~H"""
            <textarea rows="3" cols="40" disabled class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
              {{value!(Map.get(record, attribute.name))}}
            </textarea>
            """

          true ->
            ~H"""
            <textarea rows="1" cols="20" disabled class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
              {{value!(Map.get(record, attribute.name))}}
            </textarea>
            """
        end
      else
        ~H"""
        {{ value!(Map.get(record, attribute.name)) }}
        """
      end
    end
  end

  defp value!(value) do
    Phoenix.HTML.Safe.to_iodata(value)
  rescue
    _ ->
      "..."
  end

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
