defmodule AshAdmin.Components.Resource.Table do
  @moduledoc false
  use Surface.Component

  import AshAdmin.Helpers
  alias Surface.Components.LiveRedirect

  prop(attributes, :any, default: nil)
  prop(data, :list, default: nil)
  prop(resource, :any, required: true)
  prop(actions, :boolean, default: true)
  prop(api, :any, required: true)
  prop(set_actor, :event, required: true)
  prop(table, :any, required: true)
  prop(prefix, :any, required: true)

  def render(assigns) do
    ~H"""
    <div>
      <table class="rounded-t-lg m-5 w-5/6 mx-auto text-left">
        <thead class="text-left border-b-2">
          <th :for={{ attribute <- attributes(@resource, @attributes) }}>
            {{ to_name(attribute.name) }}
          </th>
        </thead>
        <tbody>
          <tr :for={{ record <- @data }} class="border-b-2">
            <td :for={{ attribute <- attributes(@resource, @attributes) }} class="py-3">{{ render_attribute(record, attribute) }}</td>
            <td :if={{ @actions && actions?(@resource) }}>
              <div class="flex h-max justify-items-center">
                <div :if={{ AshAdmin.Resource.show_action(@resource) }}>
                  <LiveRedirect to={{ ash_show_path(@prefix, @api, @resource, record, @table) }}>
                    {{ {:safe, Heroicons.Solid.information_circle(class: "h-5 w-5 text-gray-500")} }}
                  </LiveRedirect>
                </div>

                <div :if={{ Ash.Resource.Info.primary_action(@resource, :update) }}>
                  <LiveRedirect to={{ash_update_path(
                    @prefix,
                    @api,
                    @resource,
                    record,
                    Ash.Resource.Info.primary_action(@resource, :update).name,
                    @table
                  )}}>
                    {{ {:safe, Heroicons.Solid.pencil(class: "h-5 w-5 text-gray-500")} }}
                  </LiveRedirect>
                </div>

                <div :if={{ Ash.Resource.Info.primary_action(@resource, :destroy) }}>
                  <LiveRedirect to={{ash_destroy_path(
                    @prefix,
                    @api,
                    @resource,
                    record,
                    Ash.Resource.Info.primary_action(@resource, :destroy).name,
                    @table
                  )}}>
                    {{ {:safe, Heroicons.Solid.x_circle(class: "h-5 w-5 text-gray-500")} }}
                  </LiveRedirect>
                </div>

                <button
                  :if={{ AshAdmin.Resource.actor?(@resource) }}
                  :on-click={{ @set_actor }}
                  phx-value-resource={{ @resource }}
                  phx-value-api={{ @api }}
                  phx-value-pkey={{ encode_primary_key(record) }}
                >
                  {{ {:safe, Heroicons.Solid.key(class: "h-5 w-5 text-gray-500")} }}
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp attributes(resource, nil) do
    Ash.Resource.Info.attributes(resource)
  end

  defp attributes(resource, attributes) do
    attributes
    |> Enum.map(&Ash.Resource.Info.attribute(resource, &1))
    |> Enum.filter(& &1)
  end

  defp render_attribute(record, attribute) do
    if Ash.Type.embedded_type?(attribute.type) do
      "..."
    else
      record
      |> Map.get(attribute.name)
      |> Phoenix.HTML.Safe.to_iodata()
    end
  rescue
    _ ->
      "..."
  end

  defp actions?(resource) do
    Ash.Resource.Info.primary_action(resource, :update) || AshAdmin.Resource.show_action(resource) ||
      AshAdmin.Resource.actor?(resource) || Ash.Resource.Info.primary_action(resource, :destroy)
  end
end
