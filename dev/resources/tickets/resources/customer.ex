defmodule Demo.Tickets.Customer do
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
    label_field :full_name

    form do
      field :photo do
        max_file_size 8_000_000
        accepted_extensions ["image/*"]
      end
    end
  end

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
      authorize_if expr(id == ^actor(:id))
      authorize_if relates_to_actor_via([:reported_tickets, :representative])
    end
  end

  actions do
    default_accept :*
    defaults [:read]

    update :edit_tickets do
      require_atomic? false

      argument :photo, :file
      argument :tickets, {:array, :map}
      change manage_relationship(:tickets, :reported_tickets, type: :create)
      change {Dev.Changes.RecordFilePath, file_attribute: :photo, path_attribute: :photo_path}
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string, public?: true
    attribute :last_name, :string, public?: true
    attribute :representative, :boolean, public?: true
    attribute :photo_path, :string, public?: true, writable?: false
  end

  calculations do
    calculate :full_name, :string, concat([:first_name, :last_name], " ")
  end

  relationships do
    has_many :reported_tickets, Demo.Tickets.Ticket do
      destination_attribute :reporter_id
    end
  end
end
