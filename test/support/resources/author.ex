defmodule AshAdmin.Test.Author do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.DomainB,
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
    defaults([:read, :update, :destroy])

    create :create do
      accept([:name])
    end
  end

  admin do
    resource_group(:group_b)
  end
end
