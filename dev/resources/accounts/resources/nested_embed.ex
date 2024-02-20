defmodule Demo.Accounts.NestedEmbed do
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
    attribute :tags, {:array, :string}, default: []
  end
end
