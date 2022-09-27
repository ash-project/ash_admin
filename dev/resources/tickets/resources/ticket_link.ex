defmodule Demo.Tickets.TicketLink do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ticket_links"
    repo Demo.Repo
  end

  attributes do
    attribute :type, :atom, constraints: [
      one_of: [:causes, :caused_by, :fixes, :fixed_by]
    ], allow_nil?: false
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  relationships do
    belongs_to :source, Demo.Tickets.Ticket do
      primary_key? true
      allow_nil? false
    end

    belongs_to :destination, Demo.Tickets.Ticket do
      primary_key? true
      allow_nil? false
    end
  end
end
