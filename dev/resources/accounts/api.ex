defmodule Demo.Accounts.Api do
  @moduledoc false
  use Ash.Api

  resources do
    resource Demo.Accounts.User
  end
end
