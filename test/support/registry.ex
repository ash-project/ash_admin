defmodule AshAdmin.Test.Registry do
  use Ash.Registry

  entries do
    entry(AshAdmin.Test.Post)
  end
end
