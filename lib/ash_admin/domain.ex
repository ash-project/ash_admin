# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Domain do
  @admin %Spark.Dsl.Section{
    describe: "Configure the admin dashboard for a given domain.",
    name: :admin,
    schema: [
      name: [
        type: :string,
        doc: "The name of the domain in the dashboard. Will be derived if not set."
      ],
      show?: [
        type: :boolean,
        default: false,
        doc:
          "Whether or not this domain and its resources should be included in the admin dashboard."
      ],
      show_resources: [
        type: {:wrap_list, :atom},
        default: :*,
        doc: "List of resources that should be included in the admin dashboard"
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
          "Humanized names for each resource group to appear in the admin area. These will be used as labels in the top navigation dropdown and will be shown sorted as given. If a key for a group does not appear in this mapping, the label will not be rendered."
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@admin],
    transformers: [AshAdmin.ShowResourcesTransformer]

  @moduledoc """
  A domain extension to alter the behavior of a domain in the admin UI.
  """

  def name(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :name, nil, true) || default_name(domain)
  end

  def show?(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :show?, false, true)
  end

  def show_resources(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :show_resources, [], true)
  end

  def default_resource_page(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :default_resource_page, :schema, true)
  end

  def resource_group_labels(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :resource_group_labels, [], true)
  end

  defp default_name(domain) do
    split = domain |> Module.split()

    case List.last(split) do
      "Domain" ->
        Enum.at(split, -2)

      last ->
        last
    end
  end
end
