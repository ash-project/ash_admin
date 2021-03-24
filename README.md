# AshAdmin

![Elixir CI](https://github.com/ash-project/ash_admin/workflows/Elixir%20CI/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage Status](https://coveralls.io/repos/github/ash-project/ash_admin/badge.svg?branch=master)](https://coveralls.io/github/ash-project/ash_admin?branch=master)
[![Hex version badge](https://img.shields.io/hexpm/v/ash_admin.svg)](https://hex.pm/packages/ash_admin)

An admin UI for Ash resources. Built with Phoenix Liveview.

## Usage

First, ensure you've added ash_admin to your `mix.exs` file.

```elixir
{:ash_admin, "~> 0.1.5"}
```

## Setup

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router

  import AshAdmin.Router

  # Use your `:browser` pipeline, or use `admin_browser_pipeline` to create one. Only necessary
  # if you don't already have a functioning liveview `:browser` pipeline
  admin_browser_pipeline :browser

  scope "/" do
    # Pipe it through your browser pipeline
    pipe_through [:browser]

    ash_admin "/admin",
      apis: [MyApp.Api1, MyApp.Api2]
  end
end
```

## Configuration

See the documentation in `AshAdmin.Resource` and `AshAdmin.Api` for information on the available configuration.