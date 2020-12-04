defmodule AshAdmin.Api do
  @admin %Ash.Dsl.Section{
    describe: "Configure the admin dashboard for a given API",
    name: :admin,
    schema: [
      name: [
        type: :string
      ]
    ]
  }

  use Ash.Dsl.Extension, sections: [@admin]

  def name(api) do
    Ash.Dsl.Extension.get_opt(api, [:admin], :name, nil, true) ||
      api
      |> Module.split()
      |> Enum.at(-2)
  end
end
