defmodule AshAdmin.Components.Resource.Table do
  @moduledoc false
  use Surface.Component

  import AshAdmin.Helpers
  alias Surface.Components.LiveRedirect
  alias AshAdmin.Components.HeroIcon
  alias Ash.Resource.Relationships.{BelongsTo, HasOne}

  prop(attributes, :any, default: nil)
  prop(data, :list, default: nil)
  prop(resource, :any, required: true)
  prop(actions, :boolean, default: true)
  prop(api, :any, required: true)
  prop(set_actor, :event, required: true)
  prop(table, :any, required: true)
  prop(prefix, :any, required: true)
  prop(skip, :list, default: [])
  prop(format_fields, :any, default: [])

  def render(assigns) do
    ~H"""
    <div>
      <table class="rounded-t-lg m-5 w-5/6 mx-auto text-left">
        <thead class="text-left border-b-2">
          <th :for={{ attribute <- attributes(@resource, @attributes, @skip) }}>
            {{ to_name(attribute.name) }}
          </th>
        </thead>
        <tbody>
          <tr :for={{ record <- @data }} class="border-b-2">
            <td :for={{ attribute <- attributes(@resource, @attributes, @skip) }} class="py-3">{{ render_attribute(@api, record, attribute, @format_fields) }}</td>
            <td :if={{ @actions && actions?(@resource) }}>
              <div class="flex h-max justify-items-center">
                <div :if={{ AshAdmin.Resource.show_action(@resource) }}>
                  <LiveRedirect to={{ ash_show_path(@prefix, @api, @resource, record, @table) }}>
                    <HeroIcon name="information-circle" class="h-5 w-5 text-gray-500" />
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
                    <HeroIcon name="pencil" class="h-5 w-5 text-gray-500" />
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
                    <HeroIcon name="x-circle" class="h-5 w-5 text-gray-500" />
                  </LiveRedirect>
                </div>

                <button
                  :if={{ AshAdmin.Resource.actor?(@resource) }}
                  :on-click={{ @set_actor }}
                  phx-value-resource={{ @resource }}
                  phx-value-api={{ @api }}
                  phx-value-pkey={{ encode_primary_key(record) }}
                >
                  <HeroIcon name="key" class="h-5 w-5 text-gray-500" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp attributes(resource, nil, skip) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.reject(&(&1.name in skip))
  end

  defp attributes(resource, attributes, skip) do
    attributes
    |> Enum.map(fn x ->
      value = Ash.Resource.Info.attribute(resource, x)

      if is_nil(value) do
        Ash.Resource.Info.relationship(resource, x)
      else
        value
      end
    end)
    |> Enum.filter(& &1)
    |> Enum.reject(&(&1.name in skip))
  end

  defp render_attribute(api, record, attribute, formats) do
    if Ash.Type.embedded_type?(attribute.type) do
      "..."
    else
      process_attribute(api, record, attribute, formats)
    end
  rescue
    _ ->
      "..."
  end

  defp process_attribute(api, record, %module{} = attribute, _) when module in [HasOne, BelongsTo] do
    display_attributes = AshAdmin.Resource.relationship_display_fields(attribute.destination)

    if is_nil(display_attributes) do
      "..."
    else
      record =
        if loaded?(record, attribute.name) do
          record
        else
          api.load!(record, [{attribute.name, display_attributes}])
        end

      relationship = Map.get(record, attribute.name)

      if is_nil(relationship) do
        "None"
      else
        attributes = attributes(attribute.destination, display_attributes, [])

        attributes
        |> Enum.map(fn x -> render_attribute(api, relationship, x) end)
        |> Enum.join(" - ")
      end
    end
  end

  defp process_attribute(_, record, %Ash.Resource.Attribute{} = attribute, formats) do
    [mod, func] = Keyword.get(formats, attribute.name, [Phoenix.HTML.Safe, :to_iodata])
    data =
      record
      |> Map.get(attribute.name)
      |> (&(apply(mod, func, [&1]))).()

    format_attribute_value(data)
  end

  defp process_attribute(_, _, _) do
    "..."
  end

  defp format_attribute_value(data) do
    if is_binary(data) and !String.valid?(data) do
      "..."
    else
      data
    end
  end

  defp loaded?(record, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  defp actions?(resource) do
    Ash.Resource.Info.primary_action(resource, :update) || AshAdmin.Resource.show_action(resource) ||
      AshAdmin.Resource.actor?(resource) || Ash.Resource.Info.primary_action(resource, :destroy)
  end
end
