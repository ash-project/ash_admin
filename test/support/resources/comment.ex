# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Comment do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  actions do
    default_accept(:*)
    defaults([:read, :update, :destroy])

    create :create do
      primary?(true)
      argument(:photo, :file)
    end
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true)
  end
end
