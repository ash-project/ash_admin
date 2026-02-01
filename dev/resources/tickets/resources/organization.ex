# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Organization do
  use Ash.Resource,
    domain: Demo.Tickets.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [
      AshAdmin.Resource
    ]

  postgres do
    table "organizations"
    repo Demo.Repo
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :representatives, {:array, :map}
      change manage_relationship(:representatives,
        type: :append
      )
    end

    update :update do
      primary? true
      require_atomic? false
      argument :representatives, {:array, :map}
      change manage_relationship(:representatives,
        type: :append_and_remove
      )
    end
  end

  admin do
    label_field :name
    relationship_select_max_items 2
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, public?: true
  end

  relationships do
    has_many :tickets, Demo.Tickets.Ticket, public?: true
    has_many :representatives, Demo.Tickets.Representative, public?: true
  end
end
