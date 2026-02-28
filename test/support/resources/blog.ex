# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Blog do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  admin do
    resource_group(:group_b)
  end
end
