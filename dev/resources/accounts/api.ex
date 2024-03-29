defmodule Demo.Accounts.Api do
  @moduledoc false
  use Ash.Api,
    extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry Demo.Accounts.Registry
  end
end
