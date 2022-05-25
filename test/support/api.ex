defmodule AshAdmin.Test.Api do
  @moduledoc false
  use Ash.Api,
    extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry(AshAdmin.Test.Registry)
  end
end
