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
      get_actions: [
        type: {:list, :atom},
        doc:
          "A list of read actions that can be used to show resource details. These actions should accept arguments that produce one record e.g `get_user_by_id`."
      ],
      table_columns: [
        type: {:list, :atom},
        doc: "The list of attributes to render on the table view."
      ]
    ]
  }

  use Ash.Dsl.Extension, sections: [@admin]

  def table_columns(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :table_columns, nil, true)
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

  def get_actions(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :get_actions, false, []) || []
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
end
