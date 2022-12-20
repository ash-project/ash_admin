defmodule AshAdmin.LayoutView do
  @moduledoc false
  use AshAdmin.Web, :view
  use Phoenix.Component

  js_path = Path.join(__DIR__, "../../priv/static/js/app.js")
  css_path = Path.join(__DIR__, "../../priv/static/css/app.css")

  @external_resource js_path
  @external_resource css_path

  @app_js File.read!(js_path)
  @app_css File.read!(css_path)

  def render("app.js", _), do: @app_js
  def render("app.css", _), do: @app_css

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" phx-socket={live_socket_path(@conn)}>
    <head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0"/>
    <%= csrf_meta_tag() %>
    <title><%= assigns[:page_title] || "Ash Admin" %></title>
    <style><%= raw(render("app.css", %{})) %></style>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/9.5.1/jsoneditor.min.css" rel="stylesheet" type="text/css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/9.5.1/jsoneditor.min.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/easymde/dist/easymde.min.css">
    <script src="https://unpkg.com/easymde/dist/easymde.min.js"></script>
    </head>
    <body>
    <%= @inner_content %>
    </body>
    <script><%= raw(render("app.js", %{})) %></script>
    </html>
    """
  end

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end
end
