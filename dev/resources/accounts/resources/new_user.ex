# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.NewUser do
  @moduledoc """
  TODO
  """
  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create]
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false, public?: true
    attribute :first_name, :string, allow_nil?: false, public?: true
    attribute :last_name, :string, allow_nil?: false, public?: true
    attribute :mobile, :string, allow_nil?: false, public?: true
    attribute :address, :string, allow_nil?: false, public?: true
  end
end
