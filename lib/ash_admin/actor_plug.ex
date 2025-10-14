# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.ActorPlug do
  @moduledoc false

  @behaviour Plug

  @plug Application.compile_env(:ash_admin, :actor_plug, AshAdmin.ActorPlug.Plug)

  @callback set_actor_session(conn :: Plug.Conn.t()) :: Plug.Conn.t()
  @callback actor_assigns(socket :: Phoenix.LiveView.Socket.t(), session :: map) :: Keyword.t()

  def init(opts), do: opts

  def call(conn, _opts) do
    set_actor_session(conn)
  end

  def actor_assigns(socket, session) do
    args = [socket, session]
    apply(@plug, :actor_assigns, args)
  end

  def set_actor_session(conn) do
    args = [conn]
    apply(@plug, :set_actor_session, args)
  end
end
