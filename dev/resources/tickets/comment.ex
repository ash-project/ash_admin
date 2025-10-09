# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Comment do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Resource]

  admin do
    form do
      field :comment, type: :long_text
    end
  end

  actions do
    default_accept :*
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

    attribute :comment, :string, public?: true
    attribute :resource_id, :uuid, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :commenting_customer, Demo.Tickets.Customer, public?: true
    belongs_to :commenting_representative, Demo.Tickets.Representative, public?: true
  end
end
