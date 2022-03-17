defmodule Demo.Accounts.Registry do
  use Ash.Registry

  entries do
    entry Demo.Accounts.User
  end
end
