defmodule Demo.Repo do
  use AshPostgres.Repo, otp_app: :ash_admin

  def min_pg_version() do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def installed_extensions() do
    ["uuid-ossp", "pg_trgm", "citext", "ash-functions"]
  end
end
