defmodule Demo.Tickets.Customer do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      AshPolicyAuthorizer.Authorizer
    ]

  resource do
    base_filter representative: false
  end

  postgres do
    table "users"
    repo Demo.Repo
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if attribute(:id, not: [eq: actor(:id)])
      authorize_if relates_to_actor_via([:reported_tickets, :representative])
    end
  end

  actions do
    read :read
  end

  attributes do
    attribute :id, :uuid do
      primary_key? true
      default &Ecto.UUID.generate/0
    end

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :representative, :boolean
  end

  relationships do
    has_many :reported_tickets, Demo.Tickets.Ticket do
      destination_field :reporter_id
    end
  end
end
