defmodule Demo.Accounts.NestedEmbed do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :tags, {:array, :string}, default: [], public?: true
  end
end
