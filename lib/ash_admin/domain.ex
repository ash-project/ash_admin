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
      ],
      group: [
        type: :atom,
        default: nil,
        doc: """
        The group for filtering multiple admin dashboards. When set, this domain will only appear
        in admin routes that specify a matching group option. If not set (nil), the domain will
        only appear in admin routes without group filtering.

        Example:
          group :sub_app  # This domain will only show up in routes with group: :sub_app
        """
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@admin],
    transformers: [AshAdmin.ShowResourcesTransformer]

  @moduledoc """
  A domain extension to alter the behavior of a domain in the admin UI.

  ## Group-based Filtering

  Domains can be assigned to groups using the `group` option in the admin configuration.
  This allows you to create multiple admin dashboards, each showing only the domains that belong
  to a specific group.

  ### Example

  ```elixir
  defmodule MyApp.SomeFeatureDomain do
    use Ash.Domain,
      extensions: [AshAdmin.Domain]

    admin do
      show? true
      group :sub_app  # This domain will only appear in admin routes with group: :sub_app
    end

    # ... rest of domain configuration
  end
  ```

  Then in your router:
  ```elixir
  ash_admin "/sub_app/admin", group: :sub_app  # Will only show domains with group: :sub_app
  ```

  Note: If you add a group filter to your admin route but haven't set the corresponding group
  in your domains' admin configuration, those domains won't appear in the admin interface.
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

  def group(domain) do
    Spark.Dsl.Extension.get_opt(domain, [:admin], :group, nil, true)
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
