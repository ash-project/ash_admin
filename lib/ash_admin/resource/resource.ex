defmodule AshAdmin.Resource do
  @field %Ash.Dsl.Entity{
    describe: "Declare non-default behavior for a specific attribute",
    name: :field,
    schema: AshAdmin.Resource.Field.schema(),
    target: AshAdmin.Resource.Field,
    args: [:name]
  }

  @form %Ash.Dsl.Section{
    describe: "Configure the appearance of fields in admin forms.",
    name: :form,
    entities: [
      @field
    ]
  }

  @admin %Ash.Dsl.Section{
    describe: "Configure the admin dashboard for a given resource",
    name: :admin,
    sections: [
      @form
    ],
    schema: [
      name: [
        type: :string,
        doc: "The proper name to use when this resource appears in the admin interface"
      ],
      actor?: [
        type: :boolean,
        doc: "Whether or not this resource can be used as the actor for requests"
      ],
      show_action: [
        type: :atom,
        doc:
          "The action to use when linking to the resource/viewing a single record. Defaults to the primary read action."
      ],
      read_actions: [
        type: {:list, :atom},
        doc:
          "A list of read actions that can be used to show resource details. By default, all actions are included"
      ],
      create_actions: [
        type: {:list, :atom},
        doc:
          "A list of create actions that can be create records. By default, all actions are included"
      ],
      update_actions: [
        type: {:list, :atom},
        doc:
          "A list of update actions that can be update records. By default, all actions are included"
      ],
      destroy_actions: [
        type: {:list, :atom},
        doc:
          "A list of destroy actions that can be destroy records. By default, all actions are included"
      ],
      polymorphic_tables: [
        type: {:list, :string},
        doc: """
        For resources that use ash_postgres's polymorphism capabilities, you can provide a list of tables that should be available to
        select. These will be added to the list of derivable tables based on scanning all Apis + resources provided to ash_admin.
        """
      ],
      table_columns: [
        type: {:list, :atom},
        doc: "The list of attributes to render on the table view."
      ],
      format_fields: [
        type: {:list, :any},
        doc: "The list of fields and their formats."
      ]
    ]
  }

  use Ash.Dsl.Extension, sections: [@admin]

  @moduledoc """
  An Api extension to alter the behavior of a resource in the admin ui.

  Table of Contents:
  #{Ash.Dsl.Extension.doc_index([@admin])}

  DSL Docs:

  #{Ash.Dsl.Extension.doc([@admin])}
  """

  if Code.ensure_compiled(AshPostgres) do
    def polymorphic?(resource) do
      AshPostgres.polymorphic?(resource)
    end
  else
    def polymorphic?(_), do: false
  end

  def polymorphic_tables(resource, apis) do
    resource
    |> Ash.Dsl.Extension.get_opt([:admin], :polymorphic_tables, [], true)
    |> Enum.concat(find_polymorphic_tables(resource, apis))
    |> Enum.uniq()
  end

  def table_columns(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :table_columns, nil, true)
  end

  def format_fields(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :format_fields, nil, true)
  end

  def name(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :name, nil, true) ||
      resource
      |> Module.split()
      |> List.last()
  end

  def actor?(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :actor?, false, true)
  end

  def read_actions(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :read_actions, nil, true)
  end

  def create_actions(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :create_actions, nil, true)
  end

  def update_actions(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :update_actions, nil, true)
  end

  def destroy_actions(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :destroy_actions, nil, true)
  end

  def show_action(resource) do
    action = Ash.Dsl.Extension.get_opt(resource, [:admin], :show_action, false, [])

    if action do
      action
    else
      action = Ash.Resource.Info.primary_action(resource, :read)
      action && action.name
    end
  end

  def fields(resource) do
    Ash.Dsl.Extension.get_entities(resource, [:admin, :form])
  end

  def field(resource, name) do
    resource
    |> fields()
    |> Enum.find(fn field ->
      field.name == name
    end)
  end

  defp find_polymorphic_tables(resource, apis) do
    apis
    |> Enum.flat_map(&Ash.Api.resources/1)
    |> Enum.flat_map(&Ash.Resource.Info.relationships/1)
    |> Enum.filter(&(&1.destination == resource))
    |> Enum.map(& &1.context[:data_layer][:table])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end
end
