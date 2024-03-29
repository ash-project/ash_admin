# AshAdmin

![Elixir CI](https://github.com/ash-project/ash_admin/actions/workflows/elixir.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage Status](https://coveralls.io/repos/github/ash-project/ash_admin/badge.svg?branch=main)](https://coveralls.io/github/ash-project/ash_admin?branch=main)
[![Hex version badge](https://img.shields.io/hexpm/v/ash_admin.svg)](https://hex.pm/packages/ash_admin)

An admin UI for Ash resources. Built with Phoenix LiveView.

## Demo

https://www.youtube.com/watch?v=aFMLz3cpQ8c

## Usage

First, ensure you've added ash_admin to your `mix.exs` file.

```elixir
{:ash_admin, "~> 0.10.9"}
```

## Setup

Ensure your domains are configured in `config.exs`

```elixir
config :my_app, ash_domains: [MyApp.Foo, MyApp.Bar]
```

Add the admin extension to each domain you want to show in AshAdmin dashboard, and configure it to show. See [`AshAdmin.Domain`](https://hexdocs.pm/ash_admin/AshAdmin.Domain.html) for more configuration options.

```elixir
# In your Domain(s)
use Ash.Domain,
  extensions: [AshAdmin.Domain]

admin do
  show? true
end
```

Resources in each Domain will be included in AshAdmin. See [`AshAdmin.Resource`](https://hexdocs.pm/ash_admin/AshAdmin.Resource.html) for more resource configuration options. Specifically, if you app has an actor you will want to configure that. Ash Admin allows you to change actors and therefore doesn't rely on `Ash.set_actor`

```elixir
# In your resource that acts as an actor (e.g. User)
use Ash.Resource,
  domain: YourDomain,
  extensions: [AshAdmin.Resource]

  admin do
    actor?(true)
  end
```

Modify your router to add AshAdmin at whatever path you'd like to serve it at.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  import AshAdmin.Router

  # AshAdmin requires a Phoenix LiveView `:browser` pipeline
  # If you DO NOT have a `:browser` pipeline already, then AshAdmin has a `:browser` pipeline
  # Most applications will not need this:
  admin_browser_pipeline :browser

  scope "/" do
    # Pipe it through your browser pipeline
    pipe_through [:browser]

    ash_admin "/admin"
  end
end
```

**Note: there is no builtin security for your AshAdmin (except your apps normal policies). In most cases you will want to secure your AshAdmin routes in some way to prevent them from being public**

Now start your project (usually by running `mix phx.server` in a terminal) and visit `/admin` in your browser (or whatever path you gave to `ash_admin` in your router).

### Content Security Policy

If your app specifies a content security policy header, eg. via

```elixir
plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
```

in your router, then all of the styles and JavaScript used to power AshAdmin will be blocked by your browser.

To avoid this, you can add the default AshAdmin nonces to the `default-src` allowlist, ie.

```elixir
plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'nonce-ash_admin-Ed55GFnX' 'self'"}
```

alternatively you can supply your own nonces to the `ash_admin` route by setting a `:csp_nonce_assign_key` in the options list, ie.

```elixir
ash_admin "/admin", csp_nonce_assign_key: :csp_nonce_value
```

This will allow AshAdmin-generated inline CSS and JS blocks to execute normally.

## Configuration

See the documentation in [`AshAdmin.Resource`](https://hexdocs.pm/ash_admin/AshAdmin.Resource.html) and [`AshAdmin.Domain`](https://hexdocs.pm/ash_admin/AshAdmin.Domain.html) for information on the available configuration.

## Troubleshooting

If your Admin UI is not responding as expected. Check your browser's developer console for content-security-policy violations (see above).

## Development

To work on ash_admin, you'll want to be able to run the dev app. You'll need to have postgres setup locally, at which point you can do the following:

1. `mix ash_postgres.create`
2. `mix migrate`
3. `mix migrate_tenants`
4. `mix setup`

Then, you can start the app with: `mix dev`

If you make changes to the resources, you can generate migrations with `mix generate_migrations`

If you make changes to any of the assets (CSS or JavaScript), including updating dependencies that include assets such as LiveView, you will need to recompile the assets with `mix assets.deploy`.

## Contributors

Ash is made possible by its excellent community!

<a href="https://github.com/ash-project/ash_admin/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=ash-project/ash_admin" />
</a>

[Become a contributor](https://ash-hq.org/docs/guides/ash/latest/how_to/contribute.md)
