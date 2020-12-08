defmodule Demo.Accounts.Api do
  use Ash.Api

  resources do
    resource Demo.Accounts.User
  end
end
