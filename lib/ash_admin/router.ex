# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

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
        plug(:put_root_layout, html: {AshAdmin.Layouts, :root})
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end
    end
  end

  @doc """
  Defines an AshAdmin route.
  It expects the `path` the admin dashboard will be mounted at
  and a set of options.

  ## Options

    * `:live_socket_path` - Optional override for the socket path. it must match
      the `socket "/live", Phoenix.LiveView.Socket` in your endpoint. Defaults to `/live`.

    * `:on_mount` - Optional list of hooks to attach to the mount lifecycle.

    * `:session` - Optional extra session map or MFA tuple to be merged with the session.

    * `:csp_nonce_assign_key` - Optional assign key to find the CSP nonce value used for assets
      Supports either `atom()` or
        `%{optional(:img) => atom(), optional(:script) => atom(), optional(:style) => atom()}`   
        Defaults to `ash_admin-Ed55GFnX` for backwards compatibility.
    
    * `:live_session_name` - Optional atom to name the `live_session`. Defaults to `:ash_admin`.

  ## Examples
      defmodule MyAppWeb.Router do
        use Phoenix.Router

        scope "/" do
          import AshAdmin.Router

          # Make sure you are piping through the browser pipeline
          # If you don't have one, see `admin_browser_pipeline/1`
          pipe_through [:browser]

          ash_admin "/admin"
          ash_admin "/csp/admin", live_session_name: :ash_admin_csp, csp_nonce_assign_key: :csp_nonce_value
        end
      end
  """
  defmacro ash_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      import Phoenix.LiveView.Router
      live_socket_path = Keyword.get(opts, :live_socket_path, "/live")

      csp_nonce_assign_key =
        case opts[:csp_nonce_assign_key] do
          nil ->
            %{
              img: "ash_admin-Ed55GFnX",
              style: "ash_admin-Ed55GFnX",
              script: "ash_admin-Ed55GFnX"
            }

          key when is_atom(key) ->
            %{img: key, style: key, script: key}

          %{} = keys ->
            Map.take(keys, [:img, :style, :script])
        end

      live_session opts[:live_session_name] || :ash_admin,
        on_mount: List.wrap(opts[:on_mount]),
        session:
          {AshAdmin.Router, :__session__, [%{"prefix" => path}, List.wrap(opts[:session])]},
        root_layout: {AshAdmin.Layouts, :root} do
        live(
          "#{path}/*route",
          AshAdmin.PageLive,
          :page,
          private: %{
            live_socket_path: live_socket_path,
            ash_admin_csp_nonce: csp_nonce_assign_key
          }
        )
      end
    end
  end

  @cookies_to_replicate [
    "tenant",
    "actor_resource",
    "actor_primary_key",
    "actor_action",
    "actor_domain",
    "actor_authorizing",
    "actor_paused"
  ]

  @doc false
  def __session__(conn, [session, additional_hooks]),
    do: __session__(conn, session, additional_hooks)

  def __session__(conn, session, additional_hooks \\ []) do
    session =
      Enum.reduce(additional_hooks, session, fn {m, f, a}, acc ->
        Map.merge(acc, apply(m, f, [conn | a]) || %{})
      end)

    session = Map.put(session, "request_path", conn.request_path)

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
