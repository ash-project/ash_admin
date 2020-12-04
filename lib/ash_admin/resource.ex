defmodule AshAdmin.Resource do
  @admin %Ash.Dsl.Section{
    describe: "Configure the admin dashboard for a given resource",
    name: :admin,
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
end
