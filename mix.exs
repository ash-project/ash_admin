defmodule AshAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_admin,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test] do
    ["lib", "dev"]
  end

  defp elixirc_paths(:prod) do
    ["lib"]
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
      {:ash, "~> 1.36 and >= 1.36.12"},
      {:ash_phoenix, "~> 0.4 and >= 0.4.3"},
      {:surface, "~> 0.3.1"},
      {:phoenix_live_view, "~> 0.15.4"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:jason, "~> 1.0"},
      {:heroicons, "~> 0.1.0"},
      # Dev dependencies
      {:surface_formatter, "~> 0.3.1", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :test]},
      {:ash_postgres, "~> 0.35.3", only: [:dev, :test]},
      {:ash_policy_authorizer, "~> 0.16.0", only: [:dev, :test]}
    ]
  end
end
