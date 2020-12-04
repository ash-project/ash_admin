defmodule AshAdmin.SessionPlug do
  @behaviour Plug

  @cookies_to_replicate [
    "tenant",
    "actor_resource",
    "actor_primary_key",
    "actor_action",
    "actor_api",
    "actor_authorizing",
    "actor_paused"
  ]

  def init(_), do: []

  def call(conn, _) do
    Enum.reduce(@cookies_to_replicate, conn, fn cookie, conn ->
      case conn.req_cookies[cookie] do
        value when value in [nil, "", "null"] ->
          Plug.Conn.put_session(conn, cookie, nil)

        value ->
          Plug.Conn.put_session(conn, cookie, value)
      end
    end)
  end
end
