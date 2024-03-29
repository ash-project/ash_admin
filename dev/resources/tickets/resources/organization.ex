defmodule Demo.Tickets.Organization do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo Demo.Repo
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, public?: true
  end

  relationships do
    has_many :tickets, Demo.Tickets.Ticket, public?: true
  end
end
