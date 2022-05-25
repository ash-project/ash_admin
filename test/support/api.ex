defmodule AshAdmin.Test.Api do
  use Ash.Api,
    extensions: [AshAdmin.Api]

  admin do
    show? true
  end

  resources do
    registry(AshAdmin.Test.Registry)
  end
end
