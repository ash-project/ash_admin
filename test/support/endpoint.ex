defmodule AshAdmin.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :ash_admin

  socket("/live", Phoenix.LiveView.Socket)
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Plug.RequestId)
  plug(AshAdmin.Test.Router)
end
