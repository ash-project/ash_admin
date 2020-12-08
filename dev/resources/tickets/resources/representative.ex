defmodule Demo.Tickets.Representative do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      AshPolicyAuthorizer.Authorizer
    ]

  resource do
    base_filter representative: true

    identities do
      identity :representative_name, [:first_name, :last_name]
    end
  end

  multitenancy do
    strategy :attribute
    attribute :first_name
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
    read :read do
      primary? true
    end

    read :me do
      filter id: actor(:id)
    end
  end

  attributes do
    attribute :id, :uuid do
      primary_key?(true)
      default(&Ecto.UUID.generate/0)
    end

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
  end
end
