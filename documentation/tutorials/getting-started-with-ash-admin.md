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

## Security

You can limit access to ash_admin when using `AshAuthentication` like so:
```
scope "/" do
  # Pipe it through your browser pipeline
  pipe_through [:browser]

  ash_admin "/admin", AshAuthentication.Phoenix.LiveSession.opts(
    on_mount: [{ExampleWeb.LiveUserAuth, :admin_only}] #  <--- You can keep specific users out like so
  )
end
```

Then, we'll need to define :admin_only in our [example_web/live_user_auth.ex]:
```
def on_mount(:admin_only, _params, _session, socket) do
  # If the user is logged in, check the user role is admin.  Continue if so,
  # otherwise redirect to main page or a 403 page
  if socket.assigns[:current_user] do
    if socket.assigns[:current_user].role == :admin do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    end
  # If user isn't logged in, redirect to sign in page
  else
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
  end
end
```

Of course, the user role attribute will need to be added to our User resource in [example/accounts/user.ex]
```
alias Example.Accounts.User

attributes do
  ## ... previous attributes ...
  attribute :role, User.Role, default: :user  
end
```
Define our roles in a new file, [example/accounts/user/role.ex].  You can use whatever names you'd like:
```
defmodule Example.Accounts.User.Role do
  use Ash.Type.Enum, values: [:user, :admin, :moderator] 
end
```
If you don't want to use Ash.Type.Enum, you could update the User's attribute as such:
```
attribute :role, :atom do
    constraints [one_of: [:user, :admin, :moderator]]
    default :user
end
```
Done.  

The following steps are optional:
if you want users who use the dashboard to act “as themselves” (and thus follow any policy rules with themselves as the actor), you’ll also want to specify an actor plug:
```
defmodule ExampleWeb.AshAdminActorPlug do
  @moduledoc false
  @behaviour AshAdmin.ActorPlug

  @doc false
  @impl true
  def actor_assigns(socket, _session) do
    dispatcher = socket.assigns[:current_user]

    [actor: dispatcher]
  end

  @doc false
  @impl true
  def set_actor_session(conn), do: conn
end
```
and then configure it like so
```
config :ash_admin, :actor_plug, MyAppWeb.AshAdminActorPlug
```

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
