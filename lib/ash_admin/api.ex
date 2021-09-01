defmodule AshAdmin.Api do
  @admin %Ash.Dsl.Section{
    describe: "Configure the admin dashboard for a given API",
    name: :admin,
    schema: [
      name: [
        type: :string,
        doc: "The name of the api in the dashboard. Will be derived if not set."
      ],
      show?: [
        type: :boolean,
        default: false,
        doc: "Wether or not this api and its resources should be included in the admin dashboard"
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

  def show?(api) do
    Ash.Dsl.Extension.get_opt(api, [:admin], :show?, false, true)
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
