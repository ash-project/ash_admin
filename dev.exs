# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

# Copied/edited from phoenix_live_dashboard
# Configures the endpoint
Application.put_env(:ash_admin, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub
)

defmodule DemoWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :fetch_session
    plug :fetch_query_params
  end

  scope "/" do
    pipe_through :browser
    import AshAdmin.Router

    ash_admin("/")
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ash_admin

  socket "/live", Phoenix.LiveView.Socket
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"

  plug Plug.RequestId
  plug DemoWeb.Router
end

Application.ensure_all_started(:os_mon)
Application.put_env(:phoenix, :serve_endpoints, true)
  :erlang.system_flag(:backtrace_depth, 100)

Task.start(fn ->
  children = [
    Demo.Repo,
    DemoWeb.Endpoint,
    {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
