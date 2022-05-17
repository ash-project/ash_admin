defmodule Demo.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      Ash.Policy.Authorizer
    ],
    extensions: [
      AshAdmin.Resource
    ]

  admin do
    actor? true

    form do
      field :first_name, type: :short_text
      field :last_name, type: :short_text
    end
    table_columns [:id, :first_name, :last_name, :representative, :admin]
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if attribute(:id, eq: actor(:id))
    end
  end

  actions do
    read :me, filter: [id: actor(:id)]
    read :read, primary?: true
    read :by_id do
      argument :id, :uuid

      filter expr(id == ^arg(:id))
    end

    read :by_name do
      argument :first_name, :string, allow_nil?: false
      argument :last_name, :string, allow_nil?: false

      filter expr(first_name == ^arg(:first_name) and last_name == ^arg(:last_name))
    end

    create :create
    update :update, primary?: true
    update :update2
    destroy :destroy
  end

  postgres do
    table "users"
    repo Demo.Repo
    foreign_key_names [{:id, "tickets_reporter_id_fkey", "user still has reported tickets"}, {:id, "tickets_representative_id_fkey", "user still has assigned tickets"}]
  end

  validations do
    validate present([:first_name, :last_name], at_least: 1)
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string do
      constraints min_length: 1
    end

    attribute :last_name, :string do
      constraints min_length: 1
    end

    attribute :representative, :boolean do
      allow_nil? false
      default false
      description """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
      eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
      veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
      consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
      cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
      proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      """
    end

    attribute :admin, :boolean do
      allow_nil? false
      default false
    end

    attribute :profile, Demo.Accounts.Profile
    attribute :alternate_profiles, {:array, Demo.Accounts.Profile}
    attribute :tags, {:array, :string}

    timestamps()
  end
end
