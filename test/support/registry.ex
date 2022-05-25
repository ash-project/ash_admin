defmodule AshAdmin.Test.Registry do
  @moduledoc false
  use Ash.Registry

  entries do
    entry(AshAdmin.Test.Post)
  end
end
