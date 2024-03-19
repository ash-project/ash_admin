defmodule Demo.Repo do
  use AshPostgres.Repo, otp_app: :ash_admin

  def installed_extensions() do
    ["uuid-ossp", "pg_trgm", "citext", "ash-functions"]
  end
end
