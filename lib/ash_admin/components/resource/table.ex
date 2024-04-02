defmodule AshAdmin.Components.Resource.Table do
  @moduledoc false
  use Phoenix.Component

  import AshAdmin.Helpers
  import AshAdmin.CoreComponents
  alias Ash.Resource.Relationships.{BelongsTo, HasOne}
  alias AshAdmin.Components.Resource.SensitiveAttribute

  attr :attributes, :any, default: nil
  attr :data, :list, default: nil
  attr :resource, :any, required: true
  attr :actions, :boolean, default: true
  attr :api, :any, required: true
  attr :table, :any, required: true
  attr :prefix, :any, required: true
  attr :skip, :list, default: []
  attr :format_fields, :any, default: []
  attr :show_sensitive_fields, :list, default: []
  attr :actor, :any, default: nil

  def table(assigns) do
    ~H"""
    <div>
      <table class="rounded-t-lg m-5 w-5/6 mx-auto text-left">
        <thead class="text-left border-b-2">
          <th :for={attribute <- attributes(@resource, @attributes, @skip)}>
            <%= to_name(attribute.name) %>
          </th>
        </thead>
        <tbody>
          <tr :for={record <- @data} class="border-b-2">
            <td :for={attribute <- attributes(@resource, @attributes, @skip)} class="py-3">
              <%= render_attribute(
                @api,
                record,
                attribute,
                @format_fields,
                @show_sensitive_fields,
                @actor
              ) %>
            </td>
            <td :if={@actions && actions?(@resource)}>
              <div class="flex h-max justify-items-center">
                <div :if={AshAdmin.Resource.show_action(@resource)}>
                  <.link navigate={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&tab=show&table=#{@table}&primary_key=#{encode_primary_key(record)}"}>
                    <.icon name="hero-information-circle-solid" class="h-5 w-5 text-gray-500" />
                  </.link>
                </div>

                <div :if={AshAdmin.Helpers.primary_action(@resource, :update)}>
                  <.link navigate={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=update&tab=update&table=#{@table}&primary_key=#{encode_primary_key(record)}"}>
                    <.icon name="hero-pencil-solid" class="h-5 w-5 text-gray-500" />
                  </.link>
                </div>

                <div :if={AshAdmin.Helpers.primary_action(@resource, :destroy)}>
                  <.link navigate={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=destroy&tab=destroy&table=#{@table}&primary_key=#{encode_primary_key(record)}"}>
                    <.icon name="hero-x-circle-solid" class="h-5 w-5 text-gray-500" />
                  </.link>
                </div>

                <button
                  :if={AshAdmin.Resource.actor?(@resource)}
                  phx-click="set_actor"
                  phx-value-resource={@resource}
                  phx-value-api={@api}
                  phx-value-pkey={encode_primary_key(record)}
                >
                  <.icon name="hero-key-solid" class="h-5 w-5 text-gray-500" />
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
      value = Ash.Resource.Info.field(resource, x)

      if is_nil(value) do
        Ash.Resource.Info.relationship(resource, x)
      else
        value
      end
    end)
    |> Enum.filter(& &1)
    |> Enum.reject(&(&1.name in skip))
  end

  defp render_attribute(api, record, attribute, formats, show_sensitive_fields, actor) do
    process_attribute(api, record, attribute, formats, show_sensitive_fields, actor)
  rescue
    _ ->
      "..."
  end

  defp process_attribute(
         api,
         record,
         %module{} = attribute,
         formats,
         show_sensitive_fields,
         actor
       )
       when module in [HasOne, BelongsTo] do
    display_attributes = AshAdmin.Resource.relationship_display_fields(attribute.destination)

    if is_nil(display_attributes) do
      "..."
    else
      record =
        if loaded?(record, attribute.name) do
          record
        else
          api.load!(record, [{attribute.name, display_attributes}], actor: actor)
        end

      relationship = Map.get(record, attribute.name)

      if is_nil(relationship) do
        "None"
      else
        attributes = attributes(attribute.destination, display_attributes, [])

        Enum.map_join(attributes, " - ", fn x ->
          render_attribute(api, relationship, x, formats, show_sensitive_fields, actor)
        end)
      end
    end
  end

  defp process_attribute(_, record, %struct{} = attribute, formats, show_sensitive_fields, _actor)
       when struct in [Ash.Resource.Attribute, Ash.Resource.Aggregate, Ash.Resource.Calculation] do
    {mod, func, args} =
      Keyword.get(formats || [], attribute.name, {Phoenix.HTML.Safe, :to_iodata, []})

    data =
      record
      |> Map.get(attribute.name)
      |> (&apply(mod, func, [&1] ++ args)).()

    if Map.get(attribute, :sensitive?) &&
         not Enum.member?(show_sensitive_fields, attribute.name) do
      format_sensitive_value(data, attribute, record)
    else
      format_attribute_value(data, attribute)
    end
  end

  defp process_attribute(_api, _record, _attr, _formats, _show_sensitive_fields, _actor) do
    "..."
  end

  defp format_sensitive_value(value, attribute, record) do
    assigns = %{value: value, attribute: attribute, record: record}

    ~H"""
    <.live_component
      id={"#{@record.id}-#{@attribute.name}"}
      module={SensitiveAttribute}
      value={@value}
    >
      <%= format_attribute_value(@value, @attribute) %>
    </.live_component>
    """
  end

  defp format_attribute_value(data, %{type: Ash.Type.Binary}) when data not in [[], nil, ""] do
    assigns = %{}

    ~H"""
    <span class="italic">(binary)</span>
    """
  end

  defp format_attribute_value(data, _attribute) do
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
    AshAdmin.Helpers.primary_action(resource, :update) || AshAdmin.Resource.show_action(resource) ||
      AshAdmin.Resource.actor?(resource) || AshAdmin.Helpers.primary_action(resource, :destroy)
  end
end
