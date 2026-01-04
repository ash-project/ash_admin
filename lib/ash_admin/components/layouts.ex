# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Layouts do
  @moduledoc false
  use AshAdmin.Web, :html
  use Phoenix.Component

  phoenix_js_paths =
    for app <- ~w(phoenix phoenix_html phoenix_live_view)a do
      path = Application.app_dir(app, ["priv", "static", "#{app}.js"])
      Module.put_attribute(__MODULE__, :external_resource, path)
      path
    end

  @static_path Application.app_dir(:ash_admin, ["priv", "static"])
  @vendor_path Application.app_dir(:ash_admin, ["priv", "vendor"])

  @external_resource js_path = Path.join(@static_path, "assets/app.js")
  @external_resource css_path = Path.join(@static_path, "assets/app.css")

  # Vendor files
  @external_resource codemirror_js_path = Path.join(@vendor_path, "codemirror.min.js")
  @external_resource codemirror_css_path = Path.join(@vendor_path, "codemirror.min.css")
  @external_resource codemirror_js_mode_path = Path.join(@vendor_path, "javascript.min.js")
  @external_resource codemirror_md_mode_path = Path.join(@vendor_path, "markdown.min.js")

  @app_js """
  #{for path <- phoenix_js_paths, do: path |> File.read!() |> String.replace("//# sourceMappingURL=", "// ")}
  #{File.read!(js_path)}
  """
  @app_css File.read!(css_path)

  # Read vendor files at compile time
  @codemirror_js if File.exists?(codemirror_js_path), do: File.read!(codemirror_js_path), else: ""
  @codemirror_css if File.exists?(codemirror_css_path), do: File.read!(codemirror_css_path), else: ""
  @codemirror_js_mode if File.exists?(codemirror_js_mode_path), do: File.read!(codemirror_js_mode_path), else: ""
  @codemirror_md_mode if File.exists?(codemirror_md_mode_path), do: File.read!(codemirror_md_mode_path), else: ""

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css
  def render("codemirror.js", _), do: @codemirror_js
  def render("codemirror.css", _), do: @codemirror_css
  def render("codemirror-js-mode.js", _), do: @codemirror_js_mode
  def render("codemirror-md-mode.js", _), do: @codemirror_md_mode

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" phx-socket={live_socket_path(@conn)}>
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>{assigns[:page_title] || "Ash Admin"}</title>
        <style nonce={csp_nonce(@conn, :style)}>
          <%= raw(render("app.css", %{})) %>
        </style>
        <style nonce={csp_nonce(@conn, :style)}>
          <%= raw(render("codemirror.css", %{})) %>
        </style>
        <script nonce={csp_nonce(@conn, :script)}>
          <%= raw(render("codemirror.js", %{})) %>
        </script>
        <script nonce={csp_nonce(@conn, :script)}>
          <%= raw(render("codemirror-js-mode.js", %{})) %>
        </script>
        <script nonce={csp_nonce(@conn, :script)}>
          <%= raw(render("codemirror-md-mode.js", %{})) %>
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
      <script nonce={csp_nonce(@conn, :script)}>
        <%= raw(render("app.js", %{})) %>
      </script>
    </html>
    """
  end

  def render(assigns) do
    ~H"""
    ...
    """
  end

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  defp csp_nonce(conn, type) when type in [:script, :style, :img] do
    csp_nonce_value = conn.private.ash_admin_csp_nonce[type]

    case csp_nonce_value do
      key when is_atom(key) -> conn.assigns[csp_nonce_value]
      key when is_bitstring(key) -> csp_nonce_value
      _ -> raise("Unexpected type of :csp_nonce_assign_key")
    end
  end
end
