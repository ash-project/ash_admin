# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.Membership do
  use Ash.Resource,
    domain: Demo.Accounts.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "memberships"
    repo Demo.Repo
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  relationships do
    belongs_to :user, Demo.Accounts.User do
      public? true
      primary_key? true
      allow_nil? false
    end

    belongs_to :office, Demo.Accounts.Office do
      public? true
      primary_key? true
      allow_nil? false
    end
  end
end
