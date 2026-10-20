# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Language do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ManyToManyDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  actions do
    defaults([:read, :destroy, create: [:name], update: [:name]])
  end

  admin do
    label_field(:name)
  end
end
