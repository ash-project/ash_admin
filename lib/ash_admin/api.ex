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
    Ash.Dsl.Extension.get_opt(api, [:admin], :name, nil, true) || default_name(api)
  end

  defp default_name(api) do
    split = api |> Module.split()

    case List.last(split) do
      "Api" ->
        Enum.at(split, -2)

      last ->
        last
    end
  end
end
