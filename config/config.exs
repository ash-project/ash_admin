import Config

pg_url = System.get_env("PG_URL") || "postgres:postgres@127.0.0.1"
pg_database = System.get_env("PG_DATABASE") || "ash_admin_dev"
Application.put_env(:ash_admin, Demo.Repo, url: "ecto://#{pg_url}/#{pg_database}")

config :phoenix, :json_library, Jason
config :ash_admin, ecto_repos: [Demo.Repo]
config :ash, :use_all_identities_in_manage_relationship?, false

config :surface, :components, [
  {Surface.Components.Form.ErrorTag, default_class: "invalid-feedback"}
]

config :ash_admin, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  server: true

config :logger, level: :debug
config :phoenix, :serve_endpoints, true

if config_env() == :dev do
  config :ash_admin,
    ash_apis: [
      Demo.Accounts.Api,
      Demo.Tickets.Api
    ]

  config :git_ops,
    mix_project: AshAdmin.MixProject,
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/ash-project/ash_admin",
    # Instructs the tool to manage your mix version in your `mix.exs` file
    # See below for more information
    manage_mix_version?: true,
    # Instructs the tool to manage the version in your README.md
    # Pass in `true` to use `"README.md"` or a string to customize
    manage_readme_version: "README.md",
    version_tag_prefix: "v"
end

if config_env() == :test do
  config :ash_admin, AshAdmin.Test.Endpoint,
    url: [host: "localhost"],
    debug_errors: true,
    secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
    live_view: [signing_salt: "hMegieSe"],
    pubsub_server: AshAdmin.Test.PubSub

  config :ash, :disable_async?, true

  config :ash_admin,
    ash_apis: [
      AshAdmin.Test.Api
    ]
end
