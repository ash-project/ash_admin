# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Credential do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.SensitiveDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :token, :string do
      sensitive?(true)
      public?(true)
    end

    # listed in `show_sensitive_fields`, so always shown
    attribute :label, :string do
      sensitive?(true)
      public?(true)
    end
  end

  actions do
    default_accept(:*)
    defaults([:read, :destroy, create: :*, update: :*])
  end

  admin do
    show_sensitive_fields([:label])
    table_searchable_columns([:name, :token])
  end
end
