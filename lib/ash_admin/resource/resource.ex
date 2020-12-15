defmodule AshAdmin.Resource do
  @field %Ash.Dsl.Entity{
    describe: "Declare non-default behavior for a specific attribute",
    name: :field,
    schema: AshAdmin.Resource.Field.schema(),
    target: AshAdmin.Resource.Field,
    args: [:name, :type]
  }

  @form %Ash.Dsl.Section{
    describe:
      "Configure the appearance of fields in admin forms. Also can be used to define the order of fields",
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
      ]
    ]
  }

  use Ash.Dsl.Extension, sections: [@admin]

  def name(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :name, nil, true) ||
      resource
      |> Module.split()
      |> List.last()
  end

  def actor?(resource) do
    Ash.Dsl.Extension.get_opt(resource, [:admin], :actor?, false, true)
  end

  def fields(resource) do
    Ash.Dsl.Extension.get_entities(resource, [:form])
  end

  def field(resource, name) do
    resource
    |> fields()
    |> Enum.find(fn field ->
      field.name == name
    end)
  end
end
