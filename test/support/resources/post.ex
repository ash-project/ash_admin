# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Post do
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

    attribute :expires_at, :utc_datetime_usec do
      public?(true)
    end
  end

  actions do
    default_accept(:*)
    defaults(create: :*)

    create :create_with_photo do
      argument(:photo, :file)
      argument(:comments, {:array, :map})

      change(manage_relationship(:comments, type: :create))
    end
  end

  admin do
    resource_group(:group_a)
  end

  relationships do
    has_many :comments, AshAdmin.Test.Comment do
      public?(true)
      destination_attribute(:post_id)
    end
  end
end
