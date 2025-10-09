# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.NestedEmbed do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :tags, {:array, :string}, default: [], public?: true
  end
end
