# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.ProfileLanguage do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ManyToManyDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:profile_id, :language_id])
    end

    update :update do
      primary?(true)
      accept([:profile_id, :language_id])
    end
  end

  relationships do
    belongs_to :profile, AshAdmin.Test.Profile do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :language, AshAdmin.Test.Language do
      allow_nil?(false)
      public?(true)
    end
  end
end
