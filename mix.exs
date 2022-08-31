defmodule AshAdmin.MixProject do
  use Mix.Project

  @description """
  An admin UI for Ash Framework
  """

  @version "0.6.0-rc.0"

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

  defp elixirc_paths(:dev) do
    ["lib", "dev"]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
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
      migrate: "ash_postgres.migrate --migrations-path dev/repo/migrations",
      migrate_tenants: "ash_postgres.migrate --migrations-path dev/repo/tenant_migrations",
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
      {:ash, "~> 2.0.0-rc.0"},
      {:ash_phoenix, "~> 1.0.0-rc.0"},
      {:surface, "~> 0.7"},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_html, "~> 3.2"},
      {:jason, "~> 1.0"},
      # Dev dependencies
      {:surface_formatter, "~> 0.7", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :test]},
      {:ash_postgres, "~> 1.0.0-rc.0", only: [:dev, :test]},
      {:git_ops, "~> 2.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.23", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: [:dev, :test]},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end
end
