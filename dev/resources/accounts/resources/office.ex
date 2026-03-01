defmodule Demo.Accounts.Office do
  use Ash.Resource,
    domain: Demo.Accounts.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [
      AshAdmin.Resource
    ]

  admin do
    label_field :name
    relationship_select_max_items 10
  end

  postgres do
    table "offices"
    repo Demo.Repo
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :linked_offices, {:array, :map}

      change manage_relationship(:linked_offices,
        type: :append_and_remove,
        on_lookup: :relate_and_update,
        join_keys: [:relationship_type]
      )
    end

    update :update do
      primary? true
      argument :linked_offices, {:array, :map}

      change manage_relationship(:linked_offices,
        type: :append_and_remove,
        on_lookup: :relate_and_update,
        join_keys: [:relationship_type]
      )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :location, :string do
      public? true
    end
  end

  relationships do
    many_to_many :linked_offices, Demo.Accounts.Office do
      public? true
      through Demo.Accounts.OfficeLink
      source_attribute_on_join_resource :source_office_id
      destination_attribute_on_join_resource :destination_office_id
    end
  end
end
