defmodule Demo.Accounts.NewUser do
  @moduledoc """
  TODO
  """
  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create]
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string, allow_nil?: false
    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :mobile, :string, allow_nil?: false
    attribute :address, :string, allow_nil?: false
  end
end
