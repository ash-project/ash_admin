defmodule AshAdmin.MixProject do
  use Mix.Project

  @description """
  An admin UI for Ash Framework
  """

  @version "0.2.2"

  def project do
    [
      app: :ash_admin,
      version: @version,
      description: @description,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit]
      ],
      package: package(),
      source_url: "https://github.com/ash-project/ash_admin",
      homepage_url: "https://github.com/ash-project/ash_admin",
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

  def package do
    [
      name: :ash_admin,
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/ash-project/ash_admin"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extras: [
        "README.md"
      ]
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
      dev: "run --no-halt dev.exs --config config",
      sobelow: "sobelow --ignore XSS.Raw",
      "ash.formatter": "ash.formatter --extensions AshAdmin.Api,AshAdmin.Resource"
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
      # {:ash, "~> 1.37 and >= 1.37.1"},
      {:ash, path: "../ash", override: true},
      {:ash_phoenix, "~> 0.4 and >= 0.4.9"},
      {:surface, "~> 0.3.2"},
      {:phoenix_live_view, "~> 0.15.4"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:jason, "~> 1.0"},
      # Dev dependencies
      {:surface_formatter, "~> 0.3.1", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :test]},
      {:ash_postgres, "~> 0.35.4", only: [:dev, :test]},
      {:ash_policy_authorizer, "~> 0.16.0", only: [:dev, :test]},
      {:git_ops, "~> 2.0.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.23", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.12.0", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.13.0", only: [:dev, :test]}
    ]
  end
end
