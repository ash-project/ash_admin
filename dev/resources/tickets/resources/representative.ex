defmodule Demo.Tickets.Representative do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      AshPolicyAuthorizer.Authorizer
    ],
    extensions: [
      AshAdmin.Resource
    ]

  resource do
    base_filter representative: true

    identities do
      identity :representative_name, [:first_name, :last_name]
    end
  end

  postgres do
    table "users"
    repo Demo.Repo
    base_filter_sql "representative = true"
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if actor_attribute_equals(:representative, true)
      authorize_if relates_to_actor_via([:assigned_tickets, :reporter])
    end
  end

  actions do
    defaults []
    read :read do
      primary? true
    end

    read :me do
      filter id: actor(:id)
    end

    update :update do
      primary? true
      accept [:first_name, :last_name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :representative, :boolean
  end

  aggregates do
    count :open_ticket_count, [:assigned_tickets], filter: [not: [status: "closed"]]
  end

  calculations do
    calculate :full_name, :string, concat([:first_name, :last_name], " ")
  end

  relationships do
    has_many :assigned_tickets, Demo.Tickets.Ticket do
      destination_field :representative_id
    end

    has_many :comments, Demo.Tickets.Comment do
      relationship_context %{data_layer: %{table: "representative_comments"}}
      destination_field :resource_id
    end
  end
end
