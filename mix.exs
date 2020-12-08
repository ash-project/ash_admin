defmodule AshAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_admin,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: ["lib", "dev"],
      compilers: [:phoenix] ++ Mix.compilers(),
      aliases: aliases()
    ]
  end

  defp aliases() do
    [
      generate_migrations:
        "ash_postgres.generate_migrations --apis Demo.Accounts.Api,Demo.Tickets.Api --snapshot-path dev/resource_snapshots --migration-path dev --drop-columns",
      migrate: [
        "ecto.migrate --migrations-path dev/repo/migrations",
        "ecto.migrate --migrations-path dev/repo/tenant_migrations"
      ],
      setup: ["deps.get", "cmd npm install --prefix assets"],
      dev: "run --no-halt dev.exs --config config"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AshAdmin, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, path: "../ash", override: true},
      # "~> 1.24"},
      {:surface, "~> 0.1.1"},
      {:ash_phoenix, path: "../ash_phoenix"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:jason, "~> 1.0"},
      # Dev dependencies
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:ash_postgres, "~> 0.26.1", only: :dev},
      {:ash_policy_authorizer, "~> 0.14.0", only: :dev}
    ]
  end
end
