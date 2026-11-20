# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Fixtures for the belongs_to foreign key links. Their domains aren't in the
# test `:ash_domains`, so they don't show in the admin UI; tests pass the shown
# domains explicitly.

defmodule AshAdmin.Test.HiddenDomain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshAdmin.Test.HiddenTarget)
  end
end

defmodule AshAdmin.Test.HiddenTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.HiddenDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end
end

defmodule AshAdmin.Test.LinkDomain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show?(true)
  end

  resources do
    resource(AshAdmin.Test.LinkedNote)
    resource(AshAdmin.Test.UnlinkedNote)
    resource(AshAdmin.Test.IntegerTarget)
    resource(AshAdmin.Test.StringTarget)
  end
end

defmodule AshAdmin.Test.IntegerTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    attribute(:id, :integer, primary_key?: true, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read])
  end
end

defmodule AshAdmin.Test.StringTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    attribute(:id, :string, primary_key?: true, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read])
  end
end

defmodule AshAdmin.Test.LinkedNote do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true, domain: AshAdmin.Test.Domain)
    belongs_to(:hidden_target, AshAdmin.Test.HiddenTarget, public?: true)

    belongs_to(:integer_target, AshAdmin.Test.IntegerTarget,
      public?: true,
      attribute_type: :integer
    )

    belongs_to(:string_target, AshAdmin.Test.StringTarget, public?: true, attribute_type: :string)
  end
end

defmodule AshAdmin.Test.UnlinkedNote do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  admin do
    link_relationships?(false)
  end

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read])
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true, domain: AshAdmin.Test.Domain)
  end
end
