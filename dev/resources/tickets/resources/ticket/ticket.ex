defmodule Demo.Tickets.Ticket do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
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
    table_columns [:id, :representative, :reporter, :reporter_id, :subject, :status, :description, :reporter_name]
    format_fields [
      description: {AdminFieldFormats, :format_field, [:description]},
      inserted_at: {AdminFieldFormats, :format_field, [:inserted_at]},
      updated_at: {AdminFieldFormats, :format_field, [:updated_at]}
    ]

    form do
      field :description, type: :markdown
    end
  end

  policies do
    bypass always() do
      authorize_if actor_attribute_equals(:admin, true)
    end

    policy action_type(:read) do
      authorize_if actor_attribute_equals(:representative, true)
      authorize_if relates_to_actor_via(:reporter)
      authorize_if always()
    end

    policy changing_relationship(:reporter) do
      authorize_if relating_to_actor(:reporter)
    end
  end

  actions do
    default_accept :*
    read :reported do
      filter reporter: actor(:id)

      pagination offset?: true, countable: true, required?: false, default_limit: 25
    end

    action :ticket_count, :integer do
      run fn _, context ->
        Ash.count(__MODULE__, Ash.Context.to_opts(context))
      end
    end

    action :fake_ticket, :struct do
      constraints instance_of: __MODULE__
      run fn _, context ->
        {:ok, %__MODULE__{id: Ash.UUID.generate()}}
      end
    end

    action :map_type, :map do
      constraints fields: [foo: [type: :integer], bar: [type: :string]]
      run fn _, context ->
        {:ok, %{foo: 10, bar: "hello"}}
      end
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
      accept [:subject, :metadata, :metadatas]
      primary? true
      argument :representative, :map, allow_nil?: false
      argument :organization, :map, allow_nil?: false
      argument :tickets, {:array, :map}
      argument :photo, :file

      change manage_relationship(:organization, on_no_match: :create, on_lookup: :relate, on_match: :ignore)
      change manage_relationship(:representative, type: :append)
      change manage_relationship(:tickets, :source_links, on_lookup: {:relate_and_update, :create, :read, :all})
      change {Dev.Changes.RecordFilePath, file_attribute: :photo, path_attribute: :photo_path}
    end

    update :update do
      primary? true
      argument :organization_id, :uuid
      argument :comments, {:array, :map}
      require_atomic? false

      change manage_relationship(:organization_id, :organization, type: :append_and_remove)
      change manage_relationship(:comments, :comments, type: :direct_control)
    end

    update :assign do
      accept []
      require_atomic? false
      argument :representative, :map
      argument :reassignment_comment, :map, allow_nil?: false

      change manage_relationship(:representative, type: :append)
      change manage_relationship(:reassignment_comment, :comments, type: :create)
    end

    update :link do
      accept []
      require_atomic? false
      argument :tickets, {:array, :map}, allow_nil?: false
      argument :link_comment, :map

      # Uses the defult create action of the join table, which accepts the `type`
      change manage_relationship(:tickets, :source_links, on_lookup: {:relate_and_update, :create, :read, :all})
      change manage_relationship(:link_comment, :comments, type: :create)
    end

    update :nested_example do
      accept [:subject]
      argument :tickets, {:array, :map}
      require_atomic? false

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
      public? true
      constraints min_length: 5
    end

    attribute :metadata, Demo.Tickets.Ticket.Types.Metadata do
      public? true
    end

    attribute :metadatas, {:array, Demo.Tickets.Ticket.Types.Metadata} do
      public? true
    end

    attribute :description, :string do
      public? true
    end

    attribute :response, :string do
      public? true
    end

    attribute :status, :atom do
      public? true
      allow_nil? false
      default "new"
      constraints one_of: [:new, :investigating, :closed]
    end

    attribute :photo_path, :string, public?: true, writable?: false

    timestamps()
  end

  aggregates do
    first :reporter_name, [:reporter], :first_name
  end

  relationships do
    belongs_to :reporter, Demo.Tickets.Customer, public?: true

    belongs_to :representative, Demo.Tickets.Representative, public?: true
    belongs_to :organization, Demo.Tickets.Organization do
      public? true
      allow_nil? false
    end

    has_many :comments, Demo.Tickets.Comment do
      public? true
      relationship_context %{data_layer: %{table: "ticket_comments"}}
      destination_attribute :resource_id
    end

    many_to_many :source_links, Demo.Tickets.Ticket do
      public? true
      through Demo.Tickets.TicketLink
      source_attribute_on_join_resource :source_id
      destination_attribute_on_join_resource :destination_id
    end

    many_to_many :destination_links, Demo.Tickets.Ticket do
      public? true
      through Demo.Tickets.TicketLink
      source_attribute_on_join_resource :destination_id
      destination_attribute_on_join_resource :source_id
    end
  end
end
