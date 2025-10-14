# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.User do
  use Ash.Resource,
    domain: Demo.Accounts.Domain,
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

    read_actions [:me, :read, :by_id, :by_name]

    table_columns [:id, :first_name, :last_name, :representative, :admin, :full_name, :api_key, :date_of_birth]

    show_calculations [:multi_arguments, :is_super_admin?, :full_name, :nested_embed]
  end

  multitenancy do
    strategy :attribute
    attribute :org
    global? true
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  actions do
    default_accept :*
    read :me, filter: [id: actor(:id)]
    read :read, primary?: true
    read :by_id do
      argument :id, :uuid

      filter expr(id == ^arg(:id))
    end

    read :should_be_hidden

    read :by_name do
      argument :first_name, :string, allow_nil?: false
      argument :last_name, :string, allow_nil?: false

      filter expr(first_name == ^arg(:first_name) and last_name == ^arg(:last_name))
    end

    create :create
    update :update, primary?: true
    update :update2
    destroy :destroy

    update :add_another_user do
      argument :new_user, Demo.Accounts.NewUser, allow_nil?: false
    end

    update :add_moar_users do
      argument :new_users, {:array, Demo.Accounts.NewUser}, allow_nil?: false
    end
  end

  postgres do
    table "users"
    repo Demo.Repo
    foreign_key_names [{:id, "tickets_reporter_id_fkey", "user still has reported tickets"}, {:id, "tickets_representative_id_fkey", "user still has assigned tickets"}]
  end

  validations do
    validate present([:first_name, :last_name], at_least: 1)
  end

  calculations do
    calculate :full_name, :string, {Demo.Calculations.Concat, keys: [:first_name, :last_name]} do
      argument :separator, :string do
        allow_nil? false
        constraints [allow_empty?: true, trim?: false]
        default " "
      end
    end

    calculate :is_super_admin?, :boolean, expr(admin && representative)

    calculate :multi_arguments, :string, expr("Arg1: " <> ^arg(:arg1) <> ", Arg2: " <> (if ^arg(:arg2), do: "Yes", else: "No") <> ", Arg3: " <> ^arg(:arg3)) do
      argument :arg1, :string do
        allow_nil? false
        constraints [allow_empty?: false]
      end

      argument :arg2, :boolean

      argument :arg3, :float do
        allow_nil? true
      end
    end

    calculate :nested_embed, :string, expr(tags) do
      argument :nested_embed, Demo.Accounts.NestedEmbed, allow_nil?: false
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string do
      constraints min_length: 1
      public? true
    end

    attribute :last_name, :string do
      constraints min_length: 1
      public? true
    end

    attribute :metadata, :map do
      public? true
    end

    attribute :representative, :boolean do
      allow_nil? false
      public? true
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
      public? true
      allow_nil? false
      default false
    end

    attribute :api_key, :string do
      sensitive? true
    end

    attribute :date_of_birth, :date do
      public? true
      sensitive? true
    end

    attribute :profile, Demo.Accounts.Profile do
      public? true
    end
    attribute :alternate_profiles, {:array, Demo.Accounts.Profile} do
      public? true
    end
    attribute :type, :atom do
      public? true
      constraints one_of: [:type1, :type2]
      default :type1
    end

    attribute :types, {:array, :atom} do
      public? true
      constraints items: [one_of: [:type1, :type2]]
    end

    attribute :tags, {:array, :string} do
      public? true
    end

    attribute :org, :string

    timestamps()
  end
end
