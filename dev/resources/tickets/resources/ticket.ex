defmodule Demo.Tickets.Ticket do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      AshPolicyAuthorizer.Authorizer
    ],
    extensions: [
      AshAdmin.Resource
    ]

  admin do
    show_action :read
    table_columns [:id, :representative_id, :reporter_id, :subject, :status]
    form do
      field :description, type: :long_text
    end
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if actor_attribute_equals(:representative, true)
      authorize_if relates_to_actor_via(:reporter)
    end

    policy changing_relationship(:reporter) do
      authorize_if relating_to_actor(:reporter)
    end
  end

  actions do
    read :reported do
      filter reporter: actor(:id)

      pagination offset?: true, countable: true, required?: false, default_limit: 25
    end

    read :assigned do
      filter representative: actor(:id)
      pagination offset?: true, countable: true, required?: false, default_limit: 25
    end

    read :read do
      primary? true
      pagination [
        offset?: true,
        keyset?: true,
        default_limit: 10,
        countable: :by_default
      ]
    end

    read :keyset do
      pagination [
        keyset?: true,
        default_limit: 10
      ]
    end

    create :open do
      accept [:subject, :reporter]
    end

    update :update, primary?: true

    update :assign do
      accept [:representative]
    end

    destroy :destroy
  end

  postgres do
    table "tickets"
    repo Demo.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      allow_nil? false
      constraints min_length: 5
    end

    attribute :description, :string

    attribute :response, :string

    attribute :status, :atom do
      allow_nil? false
      default "new"
      constraints one_of: [:new, :investigating, :closed]
    end

    timestamps()
  end

  relationships do
    belongs_to :reporter, Demo.Tickets.Customer

    belongs_to :representative, Demo.Tickets.Representative

    has_many :comments, Demo.Tickets.Comment do
      context %{data_layer: %{table: "ticket_comments"}}
      destination_field :resource_id
    end
  end
end
