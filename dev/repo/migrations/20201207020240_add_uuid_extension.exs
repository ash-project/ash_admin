defmodule Demo.Repo.Migrations.AddUuidExtension do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION \"uuid-ossp\"", "DROP EXTENSION \"uuid-ossp\"")
  end
end
