defmodule AshAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_admin,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:phoenix] ++ Mix.compilers()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 1.24"},
      {:surface, "~> 0.1.1"},
      {:ash_phoenix, path: "../ash_phoenix"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:jason, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
