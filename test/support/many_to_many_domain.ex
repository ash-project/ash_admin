# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.ManyToManyDomain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
    name "ManyToMany"
  end

  resources do
    resource(AshAdmin.Test.Profile)
    resource(AshAdmin.Test.Language)
    resource(AshAdmin.Test.ProfileLanguage)
  end
end
