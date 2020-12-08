defmodule Demo.Repo do
  use AshPostgres.Repo, otp_app: :ash_admin

  def installed_extensions() do
    ["uuid-ossp"]
  end
end
