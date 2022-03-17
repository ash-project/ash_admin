defmodule Demo.Tickets.Api do
  @moduledoc false
  use Ash.Api,
    extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry Demo.Tickets.Registry
  end
end
