# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.Profile do
  use Ash.Resource,
    data_layer: :embedded,
    extensions: [AshAdmin.Resource]

  admin do
    form do
      field :bio, type: :long_text
      field :history, type: :long_text
    end
  end

  attributes do
    attribute :bio, :string, allow_nil?: false, public?: true
    attribute :history, :string, public?: true
    attribute :tags, {:array, :string}, default: [], public?: true
    attribute :metadata, :map, public?: true
    attribute :nested_embed, Demo.Accounts.NestedEmbed, public?: true
  end
end
