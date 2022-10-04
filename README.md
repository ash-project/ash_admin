# AshAdmin

![Elixir CI](https://github.com/ash-project/ash_admin/workflows/Elixir%20CI/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage Status](https://coveralls.io/repos/github/ash-project/ash_admin/badge.svg?branch=main)](https://coveralls.io/github/ash-project/ash_admin?branch=main)
[![Hex version badge](https://img.shields.io/hexpm/v/ash_admin.svg)](https://hex.pm/packages/ash_admin)

An admin UI for Ash resources. Built with Phoenix LiveView.

## Demo

https://www.youtube.com/watch?v=aFMLz3cpQ8c

## Usage

First, ensure you've added ash_admin to your `mix.exs` file.

```elixir
{:ash_admin, "~> 0.5.2"}
```

## Setup

Ensure your apis are configured in `config.exs`

```elixir
config :my_app, ash_apis: [MyApp.Foo, MyApp.Bar]
```

Add the admin extension to each api you want to show in the admin dashboard, and configure it to show

```elixir
use Ash.Api,
  extensions: [AshAdmin.Api]

admin do
  show? true
end
```

Modify your router to add ash admin at whatever path you'd like to serve it at.

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

Now start your project (usually by running `mix phx.server` in a terminal) and visit `/admin` in your browser (or whatever path you gave to `ash_admin` in your router).

## Configuration

See the documentation in [`AshAdmin.Resource`](https://hexdocs.pm/ash_admin/AshAdmin.Resource.html) and [`AshAdmin.Api`](https://hexdocs.pm/ash_admin/AshAdmin.Api.html) for information on the available configuration.

## Development

To work on ash_admin, you'll want to be able to run the dev app. You'll need to have postgres setup locally, at which point you can do the following:

1. `mix ash_postgres.create`
2. `mix migrate`
3. `mix migrate_tenants`

Then, you can start the app with: `mix dev`

If you make changes to the resources, you can generate migrations with `mix generate_migrations`


## Contributors

Ash is made possible by its excellent community!

<a href="https://github.com/ash-project/ash_admin/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=ash-project/ash_admin" />
</a>

[Become a contributor](https://ash-hq.org/docs/guides/ash/latest/how_to/contribute.md)
