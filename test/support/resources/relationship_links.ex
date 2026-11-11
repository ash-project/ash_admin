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
    resource(AshAdmin.Test.CodeTarget)
    resource(AshAdmin.Test.ForbiddenTarget)
    resource(AshAdmin.Test.StrictTarget)
    resource(AshAdmin.Test.FilteredTarget)
    resource(AshAdmin.Test.PolicyNote)
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

defmodule AshAdmin.Test.CodeTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
    attribute(:code, :string, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read, create: :*])
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
    defaults([:read, create: :*])
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true, domain: AshAdmin.Test.Domain)
    belongs_to(:hidden_target, AshAdmin.Test.HiddenTarget, public?: true)

    belongs_to(:integer_target, AshAdmin.Test.IntegerTarget,
      public?: true,
      attribute_type: :integer
    )

    belongs_to(:string_target, AshAdmin.Test.StringTarget, public?: true, attribute_type: :string)

    # References a non primary key attribute of its destination.
    belongs_to(:code_target, AshAdmin.Test.CodeTarget,
      public?: true,
      attribute_type: :string,
      destination_attribute: :code
    )
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

# Destinations with read policies, to check that foreign keys to records the
# actor can't read don't break the read that loads them.

defmodule AshAdmin.Test.ForbiddenTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read, create: :*])
  end

  policies do
    policy action_type(:read) do
      forbid_if(always())
    end
  end
end

defmodule AshAdmin.Test.StrictTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read, create: :*])
  end

  policies do
    policy action_type(:read) do
      access_type(:strict)
      authorize_if(expr(id == ^actor(:id)))
    end
  end
end

defmodule AshAdmin.Test.FilteredTarget do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read, create: :*])
  end

  policies do
    policy action_type(:read) do
      authorize_if(expr(id == ^actor(:id)))
    end
  end
end

defmodule AshAdmin.Test.PolicyNote do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.LinkDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
  end

  actions do
    defaults([:read, create: :*])
  end

  relationships do
    belongs_to(:forbidden_target, AshAdmin.Test.ForbiddenTarget, public?: true)
    belongs_to(:strict_target, AshAdmin.Test.StrictTarget, public?: true)
    belongs_to(:filtered_target, AshAdmin.Test.FilteredTarget, public?: true)
  end
end
