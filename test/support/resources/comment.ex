defmodule AshAdmin.Test.Comment do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end

    actions do
      default_accept(:*)

      create :create do
        primary?(true)
        argument(:photo, :file)
      end
    end
  end

  relationships do
    belongs_to(:post, AshAdmin.Test.Post, public?: true)
  end
end
