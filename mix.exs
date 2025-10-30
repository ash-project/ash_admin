# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.MixProject do
  use Mix.Project

  @description """
  A super-admin UI for Ash Framework, built with Phoenix LiveView.
  """

  @version "0.13.23"

  def project do
    [
      app: :ash_admin,
      version: @version,
      description: @description,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
      docs: &docs/0,
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix]
      ],
      package: package(),
      source_url: "https://github.com/ash-project/ash_admin",
      homepage_url: "https://github.com/ash-project/ash_admin",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      compilers: [:phoenix_live_view] ++ Mix.compilers()
    ]
  end

  defp elixirc_paths(:dev) do
    ["lib", "dev"]
  end

  defp elixirc_paths(:test) do
    ["test/support", "lib", "dev"]
  end

  defp elixirc_paths(:prod) do
    ["lib"]
  end

  def package do
    [
      maintainers: [
        "Zach Daniel <zach@zachdaniel.dev>"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/ash-project/ash_admin",
        "Changelog" => "https://github.com/ash-project/ash_admin/blob/main/CHANGELOG.md",
        "Discord" => "https://discord.gg/HTHRaaVPUc",
        "Website" => "https://ash-hq.org",
        "Forum" => "https://elixirforum.com/c/elixir-framework-forums/ash-framework-forum",
        "REUSE Compliance" => "https://api.reuse.software/info/github.com/ash-project/ash_admin"
      },
      source_url: "https://github.com/ash-project/ash_admin"
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      filter_modules: fn _mod, data ->
        !String.starts_with?(
          to_string(data.source_path),
          Path.expand("./dev")
        )
      end,
      extras: [
        "README.md",
        "documentation/tutorials/getting-started-with-ash-admin.md",
        "documentation/tutorials/contributing-to-ash-admin.md",
        {"documentation/dsls/DSL-AshAdmin.Domain.md",
         search_data: Spark.Docs.search_data_for(AshAdmin.Domain)},
        {"documentation/dsls/DSL-AshAdmin.Resource.md",
         search_data: Spark.Docs.search_data_for(AshAdmin.Resource)},
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Tutorials: ~r'documentation/tutorials',
        "How To": ~r'documentation/how_to',
        Topics: ~r'documentation/topics',
        DSLs: ~r'documentation/dsls',
        "About AshAdmin": [
          "CHANGELOG.md"
        ]
      ]
    ]
  end

  defp aliases() do
    [
      generate_migrations:
        "ash_postgres.generate_migrations --domains Demo.Accounts.Domain,Demo.Tickets.Domain --snapshot-path dev/resource_snapshots --migration-path dev/repo/migrations --dont-drop-columns",
      credo: "credo --strict",
      migrate: "ash_postgres.migrate --migrations-path dev/repo/migrations",
      migrate_tenants: "ash_postgres.migrate --migrations-path dev/repo/tenant_migrations",
      seed: "run dev/repo/seeds.exs --truncate",
      setup: ["deps.get", "assets.setup", "assets.build"],
      dev: "run --no-halt dev.exs --config config",
      sobelow: "sobelow --ignore XSS.Raw --skip",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
      test: ["setup", "test"],
      "spark.formatter": "spark.formatter --extensions AshAdmin.Domain,AshAdmin.Resource",
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      "spark.cheat_sheets_in_search":
        "spark.cheat_sheets_in_search --extensions AshAdmin.Domain,AshAdmin.Resource",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshAdmin.Domain,AshAdmin.Resource"
    ]
  end

  if Mix.env() == :text do
    # Run "mix help compile.app" to learn about applications.
    def application do
      [
        extra_applications: [:logger],
        mod: {AshAdmin, []}
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 3.0 and >= 3.4.63"},
      {:ash_phoenix, "~> 2.1 and >= 2.1.8"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.1-rc"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.0"},
      {:gettext, "~> 0.26 or ~> 1.0"},
      # Dev dependencies
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:simple_sat, "~> 0.1", only: [:dev, :test]},
      {:esbuild, "~> 0.7", only: [:dev, :test]},
      {:tailwind, "~> 0.3.0", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :test]},
      {:lazy_html, ">= 0.1.0", only: [:dev, :test]},
      {:ash_postgres, "~> 2.0", only: [:dev, :test]},
      {:ash_sql, "~> 0.2 and >= 0.2.56", only: [:dev, :test]},
      {:git_ops, "~> 2.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.23", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0", only: [:dev, :test]},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
