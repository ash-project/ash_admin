defmodule AshAdminTest do
  use ExUnit.Case
  doctest AshAdmin

  test "greets the world" do
    assert AshAdmin.hello() == :world
  end
end
