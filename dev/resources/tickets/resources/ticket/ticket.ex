defmodule Demo.Tickets.Ticket do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    authorizers: [
      Ash.Policy.Authorizer
    ],
    extensions: [
      AshAdmin.Resource
    ]

  alias Demo.Tickets.Ticket.AdminFieldFormats

  admin do
    show_action :read
    table_columns [:id, :representative, :reporter, :reporter_id, :subject, :status, :description]
    format_fields [
      description: {AdminFieldFormats, :format_field, [:description]}
    ]

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
      accept [:subject]
      primary? true
      argument :representative, :map, allow_nil?: false
      argument :organization, :map, allow_nil?: false
      argument :tickets, {:array, :map}

      change manage_relationship(:organization, on_no_match: :create, on_lookup: :relate, on_match: :ignore)
      change manage_relationship(:representative, type: :append)
      change manage_relationship(:tickets, :source_links, on_lookup: {:relate_and_update, :create, :read, :all})
    end

    update :update, primary?: true

    update :assign do
      accept []
      argument :representative, :map
      argument :reassignment_comment, :map, allow_nil?: false

      change manage_relationship(:representative, type: :append)
      change manage_relationship(:reassignment_comment, :comments, type: :create)
    end

    update :link do
      accept []
      argument :tickets, {:array, :map}, allow_nil?: false
      argument :link_comment, :map, type: :create

      # Uses the defult create action of the join table, which accepts the `type`
      change manage_relationship(:tickets, :source_links, on_lookup: {:relate_and_update, :create, :read, :all})
      change manage_relationship(:link_comment, :comments, type: :create)
    end

    update :nested_example do
      accept [:subject]
      argument :tickets, {:array, :map}

      change manage_relationship(
        :tickets,
        :source_links,
        type: :direct_control,
        on_match: {:update, :nested_example, :update, [:type]},
        on_no_match: {:create, :open, :create, [:type]}
      )
    end

    destroy :destroy do
      primary? true
    end
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
    belongs_to :organization, Demo.Tickets.Organization do
      required? true
    end

    has_many :comments, Demo.Tickets.Comment do
      relationship_context %{data_layer: %{table: "ticket_comments"}}
      destination_attribute :resource_id
    end

    many_to_many :source_links, Demo.Tickets.Ticket do
      through Demo.Tickets.TicketLink
      source_attribute_on_join_resource :source_id
      destination_attribute_on_join_resource :destination_id
    end

    many_to_many :destination_links, Demo.Tickets.Ticket do
      through Demo.Tickets.TicketLink
      source_attribute_on_join_resource :destination_id
      destination_attribute_on_join_resource :source_id
    end
  end
end
