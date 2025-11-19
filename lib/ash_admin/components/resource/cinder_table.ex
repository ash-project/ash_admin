# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.CinderTable do
  @moduledoc """
  Cinder-based table component for displaying Ash resources with sorting capabilities.

  This component wraps Cinder.Table to provide:
  - Automatic column generation from resource attributes
  - Custom cell rendering for relationships, sensitive fields, and special types
  - Action buttons (Show, Edit, Delete, Set Actor)
  - Sorting with visual indicators
  - Integrated pagination
  """
  use Phoenix.Component

  import AshAdmin.Helpers
  import AshAdmin.CoreComponents
  alias Ash.Resource.Relationships.{BelongsTo, HasOne}
  alias AshAdmin.Components.Resource.Helpers.FormatHelper
  alias AshAdmin.Components.Resource.SensitiveAttribute

  attr :resource, :any, required: true
  attr :domain, :any, required: true
  attr :query, :any, default: nil
  attr :data, :any, default: nil
  attr :table, :any, default: nil
  attr :prefix, :any, required: true
  attr :actor, :any, default: nil
  attr :tenant, :any, default: nil
  attr :attributes, :any, default: nil
  attr :skip, :list, default: []
  attr :format_fields, :any, default: []
  attr :show_sensitive_fields, :list, default: []
  attr :actions, :boolean, default: true
  attr :page_size, :integer, default: 25
  attr :theme, :string, default: "modern"
  attr :relationship_name, :atom, default: nil

  def table(assigns) do
    # Prepare action buttons as a separate component to avoid nesting issues
    assigns = assign(assigns, :has_actions, assigns.actions && has_actions?(assigns.resource))
    # Build query opts for Cinder including load specifications
    assigns = assign(assigns, :query_opts, build_query_opts(assigns))

    ~H"""
    <div class="ash-admin-cinder-table">
      <Cinder.Table.table
        id={"cinder-table-#{@resource}"}
        resource={@resource}
        scope={build_scope(@domain, @actor, @tenant)}
        query_opts={@query_opts}
        page_size={@page_size}
        theme={@theme}
        show_pagination={true}
        show_filters={true}
        class="rounded-t-lg m-5 w-5/6 mx-auto"
        loading_message="Loading..."
      >
        <:col
          :let={record}
          :for={attribute <- get_displayed_attributes(@resource, @attributes, @skip)}
          field={to_string(attribute.name)}
          label={to_name(attribute.name)}
          sort={sortable?(attribute)}
          filter={filterable_type(attribute)}
          search
        >
          {render_cell(
            @domain,
            record,
            attribute,
            @format_fields,
            @show_sensitive_fields,
            @actor,
            @relationship_name
          )}
        </:col>
        <:col :let={record} :if={@has_actions} label="Actions" class="actions-column">
          {render_actions(assigns, record)}
        </:col>
      </Cinder.Table.table>
    </div>
    """
  end

  defp render_actions(assigns, record) do
    assigns = assign(assigns, :record, record)

    ~H"""
    <div class="flex h-max justify-items-center space-x-1">
      <.link
        :if={AshAdmin.Resource.show_action(@resource)}
        navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&table=#{@table}&primary_key=#{encode_primary_key(@record)}&action_type=read"}
      >
        <.icon name="hero-information-circle-solid" class="h-5 w-5 text-gray-500" />
      </.link>

      <.link
        :if={AshAdmin.Helpers.primary_action(@resource, :update)}
        navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=update&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
      >
        <.icon name="hero-pencil-solid" class="h-5 w-5 text-gray-500" />
      </.link>

      <.link
        :if={AshAdmin.Helpers.primary_action(@resource, :destroy)}
        navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=destroy&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
      >
        <.icon name="hero-x-circle-solid" class="h-5 w-5 text-gray-500" />
      </.link>

      <button
        :if={AshAdmin.Resource.actor?(@resource)}
        phx-click="set_actor"
        phx-value-resource={@resource}
        phx-value-domain={@domain}
        phx-value-pkey={encode_primary_key(@record)}
      >
        <.icon name="hero-key-solid" class="h-5 w-5 text-gray-500" />
      </button>
    </div>
    """
  end

  @doc """
  Build scope for Cinder which includes domain, actor, and tenant.
  """
  def build_scope(domain, actor, tenant) do
    %{
      domain: domain,
      actor: actor,
      tenant: tenant
    }
  end

  # Build query options for Cinder to use when executing Ash queries.
  # Only include options that Cinder supports:
  # [:load, :select, :tenant, :timeout, :authorize?, :max_concurrency]
  defp build_query_opts(assigns) do
    opts = []

    # Determine what to load based on attributes and relationships
    display_attrs = get_displayed_attributes(assigns.resource, assigns.attributes, [])

    # Get relationship loads
    relationship_loads =
      display_attrs
      |> Enum.filter(fn
        %HasOne{} -> true
        %BelongsTo{} -> true
        _ -> false
      end)
      |> Enum.map(fn rel ->
        display_fields = AshAdmin.Resource.relationship_display_fields(rel.destination)

        if display_fields && display_fields != [] do
          {rel.name, display_fields}
        else
          rel.name
        end
      end)
      |> Enum.filter(& &1)

    # Add load to opts if there are relationships to load
    if relationship_loads != [], do: Keyword.put(opts, :load, relationship_loads), else: opts
  end

  @doc """
  Build Ash query with necessary preloads for display attributes.
  """
  def build_query(base_query, resource, attributes, skip) do
    display_attrs = get_displayed_attributes(resource, attributes, skip)

    # Get relationship attributes that need to be loaded
    relationship_loads =
      display_attrs
      |> Enum.filter(fn
        %HasOne{} -> true
        %BelongsTo{} -> true
        _ -> false
      end)
      |> Enum.map(fn rel ->
        display_fields = AshAdmin.Resource.relationship_display_fields(rel.destination)
        {rel.name, display_fields || []}
      end)
      |> Enum.reject(fn {_name, fields} -> fields == [] end)

    # Apply loads to query
    if relationship_loads != [] do
      Ash.Query.load(base_query, relationship_loads)
    else
      base_query
    end
  end

  @doc """
  Get list of attributes to display in table.
  """
  def get_displayed_attributes(resource, nil, skip) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.reject(&(&1.name in skip))
  end

  def get_displayed_attributes(resource, attributes, skip) do
    attributes
    |> Enum.map(fn attr_name ->
      Ash.Resource.Info.field(resource, attr_name)
    end)
    |> Enum.filter(& &1)
    |> Enum.reject(&(&1.name in skip))
  end

  @doc """
  Determine if an attribute should be sortable.
  """
  def sortable?(%module{}) when module in [HasOne, BelongsTo], do: false
  def sortable?(%Ash.Resource.Calculation{}), do: false
  def sortable?(%Ash.Resource.Aggregate{kind: :list}), do: false
  def sortable?(%Ash.Resource.Attribute{}), do: true
  def sortable?(%Ash.Resource.Aggregate{}), do: true
  def sortable?(_), do: false

  @doc """
  Determine the filter type for an attribute.
  Returns false for non-filterable attributes, or a filter type atom for filterable ones.
  """
  def filterable_type(%module{}) when module in [HasOne, BelongsTo], do: false
  def filterable_type(%Ash.Resource.Calculation{}), do: false
  def filterable_type(%Ash.Resource.Aggregate{kind: :list}), do: false

  def filterable_type(%Ash.Resource.Attribute{type: type}) do
    cond do
      type == Ash.Type.String -> :text
      type == Ash.Type.CiString -> :text
      type == Ash.Type.UUID -> false
      type == Ash.Type.Boolean -> :boolean
      type == Ash.Type.Date -> :date_range
      type == Ash.Type.UtcDatetime -> :date_range
      type == Ash.Type.UtcDatetimeUsec -> :date_range
      type == Ash.Type.NaiveDatetime -> :date_range
      type == Ash.Type.Integer -> :number_range
      type == Ash.Type.Float -> :number_range
      type == Ash.Type.Decimal -> :number_range
      true -> false
    end
  end

  def filterable_type(%Ash.Resource.Aggregate{}), do: false
  def filterable_type(_), do: false

  @doc """
  Render a cell value with custom formatting.
  """
  def render_cell(
        domain,
        record,
        attribute,
        formats,
        show_sensitive_fields,
        actor,
        relationship_name
      ) do
    process_attribute(
      domain,
      record,
      attribute,
      formats,
      show_sensitive_fields,
      actor,
      relationship_name
    )
  rescue
    _ ->
      "..."
  end

  # Handle relationship attributes (BelongsTo, HasOne)
  defp process_attribute(
         domain,
         record,
         %module{} = attribute,
         formats,
         show_sensitive_fields,
         actor,
         relationship_name
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
          Ash.load!(record, [{attribute.name, display_attributes}], actor: actor, domain: domain)
        end

      relationship = Map.get(record, attribute.name)

      if is_nil(relationship) do
        "None"
      else
        attributes = get_displayed_attributes(attribute.destination, display_attributes, [])

        Enum.map_join(attributes, " - ", fn x ->
          render_cell(
            domain,
            relationship,
            x,
            formats,
            show_sensitive_fields,
            actor,
            relationship_name
          )
        end)
      end
    end
  end

  # Handle regular attributes, aggregates, and calculations
  defp process_attribute(
         _domain,
         record,
         %struct{} = attribute,
         formats,
         show_sensitive_fields,
         _actor,
         relationship_name
       )
       when struct in [Ash.Resource.Attribute, Ash.Resource.Aggregate, Ash.Resource.Calculation] do
    data = FormatHelper.format_attribute(formats, record, attribute)

    if Map.get(attribute, :sensitive?) &&
         not Enum.member?(show_sensitive_fields, attribute.name) do
      format_sensitive_value(data, attribute, record, relationship_name)
    else
      format_attribute_value(data, attribute)
    end
  end

  # Fallback for unknown attribute types
  defp process_attribute(
         _domain,
         _record,
         _attr,
         _formats,
         _show_sensitive_fields,
         _actor,
         _relationship_name
       ) do
    "..."
  end

  # Format sensitive values with masking LiveComponent
  defp format_sensitive_value(value, attribute, record, relationship_name) do
    assigns = %{
      value: value,
      attribute: attribute,
      record: record,
      relationship_name: relationship_name
    }

    ~H"""
    <.live_component
      id={"#{@relationship_name}-#{encode_primary_key(@record)}-#{@attribute.name}"}
      module={SensitiveAttribute}
      value={@value}
    >
      {format_attribute_value(@value, @attribute)}
    </.live_component>
    """
  end

  # Format binary attributes
  defp format_attribute_value(data, %{type: Ash.Type.Binary}) when data not in [[], nil, ""] do
    assigns = %{}

    ~H"""
    <span class="italic">(binary)</span>
    """
  end

  # Format union type attributes
  defp format_attribute_value(%Ash.Union{value: value, type: type}, attribute) do
    config = attribute.constraints[:types][type]
    new_attr = %{attribute | type: config[:type], constraints: config[:constraints]}
    format_attribute_value(value, new_attr)
  end

  # Format regular attributes
  defp format_attribute_value(data, attribute) do
    if Ash.Type.NewType.new_type?(attribute.type) do
      constraints = Ash.Type.NewType.constraints(attribute.type, attribute.constraints)
      type = Ash.Type.NewType.subtype_of(attribute.type)
      attribute = %{attribute | type: type, constraints: constraints}
      format_attribute_value(data, attribute)
    else
      if is_binary(data) and !String.valid?(data) do
        "..."
      else
        data
      end
    end
  end

  # Check if relationship is loaded
  defp loaded?(record, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  # Check if resource has any actions to display
  defp has_actions?(resource) do
    AshAdmin.Helpers.primary_action(resource, :update) ||
      AshAdmin.Resource.show_action(resource) ||
      AshAdmin.Resource.actor?(resource) ||
      AshAdmin.Helpers.primary_action(resource, :destroy)
  end
end
