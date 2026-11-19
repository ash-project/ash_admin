# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.ActorPlug do
  @moduledoc false
  # The actor plug is chosen at compile time, so the test suite configures this one.
  # It behaves like the default plug, except on routes whose session carries
  # "custom_actor_plug", where it behaves like the custom plug the getting started
  # guide shows: the actor comes from the host app, and nothing else is returned.
  # When it is "with_tenant", the plug also sets the tenant. When it is "with_controls",
  # it sets the tenant and gives the dashboard user the actor and tenant controls.
  @behaviour AshAdmin.ActorPlug

  @impl true
  def actor_assigns(_socket, %{"custom_actor_plug" => true}), do: [actor: nil]

  def actor_assigns(_socket, %{"custom_actor_plug" => "with_tenant"}),
    do: [actor: nil, tenant: "acme"]

  def actor_assigns(_socket, %{"custom_actor_plug" => "with_controls"}),
    do: [actor: nil, tenant: "acme", actor_controls?: true, tenant_controls?: true]

  def actor_assigns(socket, session), do: AshAdmin.ActorPlug.Plug.actor_assigns(socket, session)

  @impl true
  def set_actor_session(conn), do: AshAdmin.ActorPlug.Plug.set_actor_session(conn)

  @doc false
  def custom_session(_conn), do: %{"custom_actor_plug" => true}

  @doc false
  def custom_session_with_tenant(_conn), do: %{"custom_actor_plug" => "with_tenant"}

  @doc false
  def custom_session_with_controls(_conn), do: %{"custom_actor_plug" => "with_controls"}
end
