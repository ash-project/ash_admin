# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource do
  @field %Spark.Dsl.Entity{
    describe: "Declare non-default behavior for a specific attribute.",
    name: :field,
    schema: AshAdmin.Resource.Field.schema(),
    target: AshAdmin.Resource.Field,
    args: [:name]
  }

  @form %Spark.Dsl.Section{
    describe: "Configure the appearance of fields in admin forms.",
    name: :form,
    entities: [
      @field
    ]
  }

  @admin %Spark.Dsl.Section{
    describe: "Configure the admin dashboard for a given resource.",
    name: :admin,
    sections: [
      @form
    ],
    schema: [
      name: [
        type: :string,
        doc: "The proper name to use when this resource appears in the admin interface."
      ],
      actor_load: [
        type: :any,
        doc: "A load statement to apply on the actor when fetching it"
      ],
      actor?: [
        type: :boolean,
        doc: "Whether or not this resource can be used as the actor for requests."
      ],
      show_action: [
        type: :atom,
        doc:
          "The action to use when linking to the resource/viewing a single record. Defaults to the primary read action."
      ],
      read_actions: [
        type: {:list, :atom},
        doc:
          "A list of read actions that can be used to show resource details. By default, all actions are included."
      ],
      generic_actions: [
        type: {:list, :atom},
        doc:
          "A list of generic actions that can be used to show resource details. By default, all actions are included."
      ],
      create_actions: [
        type: {:list, :atom},
        doc:
          "A list of create actions that can create records. By default, all actions are included."
      ],
      update_actions: [
        type: {:list, :atom},
        doc:
          "A list of update actions that can be used to update records. By default, all actions are included."
      ],
      destroy_actions: [
        type: {:list, :atom},
        doc:
          "A list of destroy actions that can be used to destroy records. By default, all actions are included."
      ],
      polymorphic_tables: [
        type: {:list, :string},
        doc: """
        For resources that use ash_postgres' polymorphism capabilities, you can provide a list of tables that should be available to select. These will be added to the list of derivable tables based on scanning all domains and resources provided to ash_admin.
        """
      ],
      polymorphic_actions: [
        type: {:list, :atom},
        doc: """
        For resources that use ash_postgres' polymorphism capabilities, you can provide a list of actions that should require a table to be set. If this is not set, then *all* actions will require tables.
        """
      ],
      table_columns: [
        type: {:list, :atom},
        doc: "The list of attributes to render on the table view."
      ],
      format_fields: [
        type: {:list, :any},
        doc: """
        The list of fields and their formats represented as a MFA. For example: `updated_at: {Timex, :format!, ["{0D}-{0M}-{YYYY} {h12}:{m} {AM}"]}`. Datatable pages format all given fields. Show and Update pages format given read-only fields of types `Ash.Type.Date`, `Ash.Type.DateTime`, `Ash.Type.Time`, `Ash.Type.NaiveDatetime`, `Ash.Type.UtcDatetime` and `Ash.Type.UtcDatetimeUsec`.
        """
      ],
      relationship_display_fields: [
        type: {:list, :atom},
        doc:
          "The list of attributes to render when this resource is shown as a relationship on another resource's datatable."
      ],
      resource_group: [
        type: :atom,
        doc: "The group in the top resource dropdown that the resource appears in."
      ],
      show_sensitive_fields: [
        type: {:list, :atom},
        doc:
          "The list of fields that should not be redacted in the admin UI even if they are marked as sensitive."
      ],
      show_calculations: [
        type: {:list, :atom},
        doc:
          "A list of calculation that can be calculate when this resource is shown. By default, all calculations are included."
      ],
      label_field: [
        type: :atom,
        doc:
          "The field to use as the label when the resource appears in a relationship select or typeahead field on another resource's form."
      ],
      relationship_select_max_items: [
        type: :integer,
        default: 50,
        doc:
          "The maximum number of items to show in a select field when this resource is shown as a relationship on another resource's form. If the number of related resources is higher, a typeahead selector will be used."
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@admin],
    transformers: [
      AshAdmin.Resource.Transformers.ValidateTableColumns,
      AshAdmin.Resource.Transformers.AddPositionSortCalculation
    ],
    verifiers: [
      AshAdmin.Resource.Verifiers.VerifyFileArgumentsExist
    ]

  @moduledoc """
  A resource extension to alter the behaviour of a resource in the admin UI.
  """

  def polymorphic?(resource, domains) do
    polymorphic_tables(resource, domains) not in [nil, []]
  end

  def polymorphic_tables(resource, domains) do
    resource
    |> Spark.Dsl.Extension.get_opt([:admin], :polymorphic_tables, [], true)
    |> Enum.concat(find_polymorphic_tables(resource, domains))
    |> Enum.uniq()
  end

  def polymorphic_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :polymorphic_actions, nil, true)
  end

  def relationship_display_fields(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :relationship_display_fields, nil, true)
  end

  def table_columns(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :table_columns, nil, true) ||
      Enum.map(Ash.Resource.Info.attributes(resource), & &1.name)
  end

  def format_fields(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :format_fields, nil, true)
  end

  def name(resource) do
    case Spark.Dsl.Extension.get_opt(resource, [:admin], :name, nil, true) do
      nil ->
        split = Module.split(resource)

        if List.last(split) == "Version" and version?(resource) do
          split
          |> Enum.reverse()
          |> Enum.take(2)
          |> Enum.reverse()
          |> Enum.join(".")
        else
          List.last(split)
        end

      v ->
        v
    end
  end

  defp version?(resource) do
    resource.resource_version?()
  rescue
    _ ->
      false
  end

  def resource_group(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :resource_group, nil, true)
  end

  def show_sensitive_fields(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :show_sensitive_fields, [], true)
  end

  def label_field(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :label_field, nil, true)
  end

  def relationship_select_max_items(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :relationship_select_max_items, 50, true)
  end

  def actor?(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :actor?, false, true)
  end

  def actor_load(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :actor_load, [], true)
  end

  def read_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :read_actions, nil, true) ||
      actions_with_primary_first(resource, :read)
  end

  def generic_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :generic_actions, nil, true) ||
      actions_with_primary_first(resource, :action)
  end

  def create_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :create_actions, nil, true) ||
      actions_with_primary_first(resource, :create)
  end

  def update_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :update_actions, nil, true) ||
      actions_with_primary_first(resource, :update)
  end

  def destroy_actions(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :destroy_actions, nil, true) ||
      actions_with_primary_first(resource, :destroy)
  end

  def show_action(resource) do
    action = Spark.Dsl.Extension.get_opt(resource, [:admin], :show_action, false, [])

    if action do
      action
    else
      action = AshAdmin.Helpers.primary_action(resource, :read)
      action && action.name
    end
  end

  def show_calculations(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:admin], :show_calculations, [], true)
  end

  def fields(resource) do
    Spark.Dsl.Extension.get_entities(resource, [:admin, :form])
  end

  def field(resource, name) do
    resource
    |> fields()
    |> Enum.find(fn field ->
      field.name == name
    end)
  end

  defp find_polymorphic_tables(resource, domains) do
    domains
    |> Enum.flat_map(&AshAdmin.Domain.show_resources/1)
    |> Enum.flat_map(&Ash.Resource.Info.relationships/1)
    |> Enum.filter(&(&1.destination == resource))
    |> Enum.map(& &1.context[:data_layer][:table])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [] ->
        []

      tables ->
        Enum.concat(
          [
            Spark.Dsl.Extension.get_opt(resource, [:postgres], :table),
            Spark.Dsl.Extension.get_opt(resource, [:sqlite], :table)
          ],
          tables
        )
    end
    |> Enum.reject(&is_nil/1)
  end

  defp actions_with_primary_first(resource, type) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.filter(&(&1.type == type))
    |> Enum.sort_by(&(!Map.get(&1, :primary?)))
    |> Enum.map(& &1.name)
  end
end
