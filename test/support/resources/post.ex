defmodule AshAdmin.Test.Post do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
    end
  end
end
