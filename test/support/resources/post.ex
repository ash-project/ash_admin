defmodule AshAdmin.Test.Post do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.DomainA,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :expires_at, :utc_datetime_usec do
      public?(true)
    end
  end

  actions do
    default_accept(:*)
    defaults(create: :*)
  end

  admin do
    resource_group(:group_a)
  end
end
