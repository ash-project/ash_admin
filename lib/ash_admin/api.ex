defmodule AshAdmin.Api do
  @admin %Ash.Dsl.Section{
    describe: "Configure the admin dashboard for a given API.",
    name: :admin,
    schema: [
      name: [
        type: :string,
        doc: "The name of the API in the dashboard. Will be derived if not set."
      ],
      show?: [
        type: :boolean,
        default: false,
        doc:
          "Whether or not this API and its resources should be included in the admin dashboard."
      ],
      default_resource_page: [
        type: {:in, [:schema, :primary_read]},
        default: :schema,
        doc:
          "Set the default page for the resource to be the primary read action or the resource schema. Schema is the default for backwards compatibility, if a resource doesn't have a primary read action it will fallback to the schema view."
      ],
      resource_group_labels: [
        type: :keyword_list,
        default: [],
        doc:
          "Humanized names for each resource group to appear in the admin area. These will be used as labels in the top navigation dropdown. If a key for a group does not appear in this mapping, the label will not be rendered."
      ]
    ]
  }

  use Ash.Dsl.Extension, sections: [@admin]

  @moduledoc """
  An API extension to alter the behavior of an API in the admin UI.

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

  def default_resource_page(api) do
    Ash.Dsl.Extension.get_opt(api, [:admin], :default_resource_page, :schema, true)
  end

  def resource_group_labels(api) do
    Ash.Dsl.Extension.get_opt(api, [:admin], :resource_group_labels, [], true)
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
