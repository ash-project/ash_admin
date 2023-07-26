defmodule Demo.Tickets.Comment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Resource]

  admin do
    form do
      field :comment, type: :long_text
    end
  end

  actions do
    defaults [:read, :update, :destroy]
    create :create do
      primary? true
      argument :foo, :utc_datetime
      argument :thing, :boolean
      argument :map, :map
    end

    create :create2
  end

  postgres do
    repo Demo.Repo
    polymorphic? true
  end

  attributes do
    uuid_primary_key :id

    attribute :comment, :string
    attribute :resource_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :commenting_customer, Demo.Tickets.Customer
    belongs_to :commenting_representative, Demo.Tickets.Customer
  end
end
