# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Language do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.ManyToManyDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  actions do
    defaults([:read, :destroy, create: [:name], update: [:name]])

    update :rename_with_receipt do
      accept([:name])
      require_atomic?(false)
      metadata(:receipt, :string)

      change(
        after_action(fn _changeset, language, _context ->
          {:ok, Ash.Resource.put_metadata(language, :receipt, "renamed to #{language.name}")}
        end)
      )
    end
  end

  admin do
    label_field(:name)
  end
end
