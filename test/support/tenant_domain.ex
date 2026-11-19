# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.TenantDomain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
    name "Tenants"
  end

  resources do
    resource(AshAdmin.Test.TenantNote)
  end
end
