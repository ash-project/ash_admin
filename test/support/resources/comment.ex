defmodule AshAdmin.Test.Comment do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.DomainA,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end
  end
end
