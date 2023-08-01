defmodule AshAdmin.Layouts do
  @moduledoc false
  use AshAdmin.Web, :html

  embed_templates "layouts/*"

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end

  def asset_hash("/statics/" <> path) do
    file =
      Application.app_dir(:ash_admin, ["priv", "static", path])
      |> File.read!()

    :crypto.hash(:md5, file)
    |> Base.encode16(case: :lower)
  end

  def asset_path(conn, asset) do
    hash = asset_hash(asset)

    ash_admin_path(conn, "#{asset}?vsn=#{hash}")
  end
end
