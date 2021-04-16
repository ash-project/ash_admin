defmodule Demo.Accounts.Profile do
  use Ash.Resource,
    data_layer: :embedded,
    extensions: [AshAdmin.Resource]

  admin do
    form do
      field :bio, type: :long_text
      field :history, type: :long_text
    end
  end

  attributes do
    attribute :bio, :string, allow_nil?: false
    attribute :history, :string
    attribute :tags, {:array, :string}, default: []
  end
end
