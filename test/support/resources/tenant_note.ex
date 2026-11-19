# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.TenantNote do
  @moduledoc false
  # Each note belongs to one tenant, so a read shows only the current tenant's notes.
  use Ash.Resource,
    domain: AshAdmin.Test.TenantDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  multitenancy do
    strategy(:attribute)
    attribute(:org)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :org, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  actions do
    defaults([:read, create: [:body]])
  end
end
