defmodule AshAdmin.Router do
  @moduledoc """
  Provides LiveView routing for AshAdmin.
  """

  @doc """
  Can be used to create a `:browser` pipeline easily if you don't have one.

  By default it is called `:browser`, but you can rename it by supplying an argument,
  for example:

  ```elixir
  defmodule MyAppWeb.Router do
    use Phoenix.Router

    import AshAdmin.Router
    admin_browser_pipeline :something

    scope "/" do

      pipe_through [:something]
      ash_admin "/admin"
    end
  end
  ```
  """
  defmacro admin_browser_pipeline(name \\ :browser) do
    quote do
      import Phoenix.LiveView.Router

      pipeline unquote(name) do
        plug(:accepts, ["html"])
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:put_root_layout, {ThingyWeb.LayoutView, :root})
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end
    end
  end

  @doc """
  Defines an AshAdmin route.
  It expects the `path` the admin dashboard will be mounted at
  and a set of options.
  ## Examples
      defmodule MyAppWeb.Router do
        use Phoenix.Router

        scope "/" do
          import AshAdmin.Router

          # Make sure you are piping through the browser pipeline
          # If you don't have one, see `admin_browser_pipeline/1`
          pipe_through [:browser]

          ash_admin "/admin"
        end
      end
  """
  defmacro ash_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      import Phoenix.LiveView.Router
      live_socket_path = Keyword.get(opts, :live_socket_path, "/live")

      live_session :ash_admin,
        session: {AshAdmin.Router, :__session__, [%{"prefix" => path}]},
        root_layout: {AshAdmin.LayoutView, :admin} do
        live(
          "#{path}/*route",
          AshAdmin.PageLive,
          :page,
          private: %{live_socket_path: live_socket_path}
        )
      end
    end
  end

  @cookies_to_replicate [
    "tenant",
    "actor_resource",
    "actor_primary_key",
    "actor_action",
    "actor_api",
    "actor_authorizing",
    "actor_paused"
  ]

  @doc false
  def __session__(conn, [session]), do: __session__(conn, session)

  def __session__(conn, session) do
    Enum.reduce(@cookies_to_replicate, session, fn cookie, session ->
      case conn.req_cookies[cookie] do
        value when value in [nil, "", "null"] ->
          Map.put(session, cookie, nil)

        value ->
          Map.put(session, cookie, value)
      end
    end)
  end
end
