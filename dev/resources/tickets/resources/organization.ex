defmodule Demo.Tickets.Organization do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo Demo.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string
  end

  relationships do
    has_many :tickets, Demo.Tickets.Ticket
  end
end
