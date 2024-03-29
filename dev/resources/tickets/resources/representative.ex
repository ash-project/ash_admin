defmodule Demo.Tickets.Representative do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      Ash.Policy.Authorizer
    ],
    extensions: [
      AshAdmin.Resource
    ]

    admin do
      relationship_display_fields [:id, :first_name]
    end

  resource do
    base_filter representative: true
  end

  identities do
    identity :representative_name, [:first_name, :last_name]
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
    default_accept :*
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

    attribute :first_name, :string, public?: true
    attribute :last_name, :string, public?: true
    attribute :representative, :boolean, public?: true
  end

  aggregates do
    count :open_ticket_count, [:assigned_tickets], filter: [not: [status: "closed"]]
  end

  calculations do
    calculate :full_name, :string, concat([:first_name, :last_name], " ")
  end

  relationships do
    has_many :assigned_tickets, Demo.Tickets.Ticket do
      public? true
      destination_attribute :representative_id
    end

    has_many :comments, Demo.Tickets.Comment do
      public? true
      relationship_context %{data_layer: %{table: "representative_comments"}}
      destination_attribute :resource_id
    end
  end
end
