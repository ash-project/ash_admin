# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.TicketLink do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ticket_links"
    repo Demo.Repo
  end

  attributes do
    attribute :type, :atom, constraints: [
      one_of: [:causes, :caused_by, :fixes, :fixed_by]
    ], allow_nil?: false, public?: true
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  relationships do
    belongs_to :source, Demo.Tickets.Ticket do
      public? true
      primary_key? true
      allow_nil? false
    end

    belongs_to :destination, Demo.Tickets.Ticket do
      public? true
      primary_key? true
      allow_nil? false
    end
  end
end
