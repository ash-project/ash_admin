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

  @moduledoc """
  An Api extension to alter the behavior of an Api in the admin ui.

  Table of Contents:
  #{Ash.Dsl.Extension.doc_index([@admin])}

  DSL Docs:

  #{Ash.Dsl.Extension.doc([@admin])}
  """

  def name(api) do
    Ash.Dsl.Extension.get_opt(api, [:admin], :name, nil, true) ||
      api
      |> Module.split()
      |> Enum.at(-2)
  end
end
