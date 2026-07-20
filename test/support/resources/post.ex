# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
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

    # primitive array field for testing drag-and-drop reorder in admin forms
    attribute :tags, {:array, :string} do
      default([])
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

    create :create_with_flag do
      argument(:flag, :boolean, allow_nil?: true)
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
