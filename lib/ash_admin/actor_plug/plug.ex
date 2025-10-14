# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.ActorPlug.Plug do
  @moduledoc false
  @behaviour AshAdmin.ActorPlug
  import AshAdmin.Helpers
  require Ash.Query

  @impl true
  def actor_assigns(socket, session) do
    otp_app = socket.endpoint.config(:otp_app)
    domains = domains(otp_app)
    session = Phoenix.LiveView.get_connect_params(socket) || session

    [
      actor: actor_from_session(socket.endpoint, session),
      actor_domain: actor_domain_from_session(socket.endpoint, session),
      actor_resources: actor_resources(domains),
      actor_paused: session_bool(session["actor_paused"], true),
      actor_tenant: session["actor_tenant"],
      authorizing: session_bool(session["actor_authorizing"], false),
      tenant: session["tenant"]
    ]
  end

  @impl true
  def set_actor_session(conn) do
    conn =
      case conn.cookies do
        %{"tenant" => tenant} when tenant != "undefined" ->
          conn
          |> Plug.Conn.put_session(:tenant, tenant)
          |> Plug.Conn.assign(:tenant, tenant)

        _ ->
          conn
      end

    case conn.cookies do
      session = %{
        "actor_resource" => resource,
        "actor_domain" => domain,
        "actor_action" => action,
        "actor_primary_key" => primary_key
      }
      when resource != "undefined" ->
        actor = actor_from_session(conn.private.phoenix_endpoint, session)
        authorizing = session_bool(session["actor_authorizing"], false)
        actor_paused = session_bool(session["actor_paused"], true)

        conn
        |> Plug.Conn.put_session(:actor_resource, resource)
        |> Plug.Conn.put_session(:actor_domain, domain)
        |> Plug.Conn.put_session(:actor_action, action)
        |> Plug.Conn.put_session(:actor_tenant, session["actor_tenant"])
        |> Plug.Conn.put_session(:actor_primary_key, primary_key)
        |> Plug.Conn.put_session(:actor_authorizing, authorizing)
        |> Plug.Conn.put_session(:actor_paused, actor_paused)
        |> Plug.Conn.assign(:actor, actor)
        |> Plug.Conn.assign(:actor_tenant, session["actor_tenant"])
        |> Plug.Conn.assign(:actor_paused, actor_paused)
        |> Plug.Conn.assign(:authorizing, authorizing)

      _ ->
        conn
    end
  end

  defp session_bool(value, default) do
    case value do
      "true" ->
        true

      "false" ->
        false

      "undefined" ->
        false

      boolean when is_boolean(boolean) ->
        boolean

      nil ->
        default
    end
  end

  defp actor_resources(domains) do
    for domain <- domains,
        resource <- AshAdmin.Domain.show_resources(domain),
        AshAdmin.Helpers.primary_action(resource, :read) && AshAdmin.Resource.actor?(resource),
        do: {domain, resource}
  end

  defp domains(otp_app) do
    otp_app
    |> Application.get_env(:ash_domains)
    |> Enum.filter(&AshAdmin.Domain.show?/1)
  end

  defp actor_domain_from_session(endpoint, %{"actor_domain" => domain}) do
    endpoint.config(:otp_app)
    |> Application.get_env(:ash_domains)
    |> Enum.find(&(AshAdmin.Domain.show?(&1) && AshAdmin.Domain.name(&1) == domain))
  end

  defp actor_domain_from_session(_, _), do: nil

  defp actor_from_session(
         endpoint,
         session = %{
           "actor_resource" => resource,
           "actor_domain" => domain,
           "actor_primary_key" => primary_key,
           "actor_action" => action,
           "actor_tenant" => tenant
         }
       )
       when not is_nil(resource) and not is_nil(domain) do
    domain = actor_domain_from_session(endpoint, session)

    resource =
      if domain do
        domain
        |> AshAdmin.Domain.show_resources()
        |> Enum.find(&(AshAdmin.Resource.name(&1) == resource))
      end

    case resource && decode_primary_key(resource, primary_key) do
      {:ok, filter} ->
        action =
          if action do
            Ash.Resource.Info.action(resource, String.to_existing_atom(action), :read)
          end

        actor_load = AshAdmin.Resource.actor_load(resource)

        resource
        |> Ash.Query.filter(^filter)
        |> Ash.Query.set_tenant(tenant)
        |> Ash.Query.load(actor_load)
        |> Ash.read_one!(action: action, authorize?: false, domain: domain)

      _ ->
        nil
    end
  end

  defp actor_from_session(_, _), do: nil
end
