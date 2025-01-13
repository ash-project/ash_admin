# Getting Started with AshAdmin

## Demo

https://www.youtube.com/watch?v=aFMLz3cpQ8c

## Installation

Add the `ash_admin` dependency to your `mix.exs` file:

```elixir
{:ash_admin, "~> 0.11.4"}
```

## Setup

<!-- tabs-open -->

### With Igniter (Recommended)

```
mix igniter.install ash_admin
```

### Manual

Modify your router to add AshAdmin at whatever path you'd like to serve it at.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  import AshAdmin.Router

  # AshAdmin requires a Phoenix LiveView `:browser` pipeline
  # If you DO NOT have a `:browser` pipeline already, then AshAdmin has a `:browser` pipeline
  # Most applications will not need this:
  admin_browser_pipeline :browser

  # NOTE: `scope/2` here does not have a second argument.
  # If it looks like `scope "/", MyAppWeb`, create a *new* scope, don't copy the contents into your scope
  scope "/" do
    # Pipe it through your browser pipeline
    pipe_through [:browser]

    ash_admin "/admin"
  end
end
```

<!-- tabs-close -->

Add the `AshAdmin.Domain` extension to each domain you want to show in the AshAdmin dashboard, and configure it to show. See [DSL: AshAdmin.Domain](/documentation/dsls/DSL-AshAdmin.Domain.md) for more configuration options.

```elixir
# In your Domain(s)
use Ash.Domain,
  extensions: [AshAdmin.Domain]

admin do
  show? true
end
```

All resources in each Domain will automatically be included in AshAdmin. To configure a resource, use the `AshAdmin.Resource` extension, and then use the [DSL: AshAdmin.Resource](/documentation/dsls/DSL-AshAdmin.Resource.md) configuration options. Specifically, if your app has an actor you will want to configure that.

```elixir
# In your resource that acts as an actor (e.g. User)
use Ash.Resource,
  domain: YourDomain,
  extensions: [AshAdmin.Resource]

admin do
  actor? true
end
```


> #### Warning {: .warning}
>
> There is no builtin security for your AshAdmin (except your app's normal policies). In most cases you will want to secure your AshAdmin routes in some way to prevent them from being publicly accessible.

Start your project (usually by running `mix phx.server` in a terminal) and visit `/admin` in your browser (or the path you configured `ash_admin` with in your router).

### Content Security Policy

If your app specifies a content security policy header, eg. via

```elixir
plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
```

in your router, then the stylesheets and JavaScript used to power AshAdmin will be blocked by your browser.

To avoid this, you can add the default AshAdmin nonces to the `default-src` allowlist, ie.

```elixir
plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'nonce-ash_admin-Ed55GFnX' 'self'"}
```

Alternatively you can supply your own nonces to the `ash_admin` route, by setting a `:csp_nonce_assign_key` in the options list, ie.

```elixir
ash_admin "/admin", csp_nonce_assign_key: :csp_nonce_value
```

This will allow AshAdmin-generated inline CSS and JS blocks to execute normally.

## Troubleshooting

#### UI issues

If your admin UI is not responding as expected, check your browser's developer console for content-security-policy violations (see above).

#### Router issues

If you are seeing the following error `(UndefinedFunctionError) function YourAppWeb.AshAdmin.PageLive.__live__/0 is undefined (module YourAppWeb.AshAdmin.PageLive is not available)` it likely means that you added the ash admin route macro under a scope with a prefix. Make sure that you add it under a scope without any prefixes.

```elixir
  # Incorrect (with YourAppWeb prefix)
  scope "/", YourAppWeb do
    pipe_through [:browser]

    ash_admin "/admin"
  end

  # Correct (without prefix)
  scope "/" do
    pipe_through [:browser]

    ash_admin "/admin"
  end
```
