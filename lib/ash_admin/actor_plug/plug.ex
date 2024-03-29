defmodule AshAdmin.ActorPlug.Plug do
  @moduledoc false
  @behaviour AshAdmin.ActorPlug
  import AshAdmin.Helpers
  require Ash.Query

  @impl true
  def actor_assigns(socket, session) do
    otp_app = socket.endpoint.config(:otp_app)
    domains = domains(otp_app)

    session =
      Phoenix.LiveView.get_connect_params(socket) || session

    actor_paused =
      if is_nil(session["actor_paused"]) do
        true
      else
        session_bool(session["actor_paused"])
      end

    [
      actor: actor_from_session(socket.endpoint, session),
      actor_domain: actor_domain_from_session(socket.endpoint, session),
      actor_resources: actor_resources(domains),
      authorizing: session_bool(session["actor_authorizing"]),
      tenant: session["tenant"],
      actor_paused: actor_paused
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
      %{"actor_resource" => "undefined"} ->
        conn

      session ->
        case session do
          %{
            "actor_resource" => resource,
            "actor_domain" => domain,
            "actor_action" => action,
            "actor_primary_key" => primary_key
          } ->
            authorizing = session["actor_authorizing"] || false

            actor_paused =
              if is_nil(session["actor_paused"]) do
                true
              else
                session["actor_paused"]
              end

            actor = actor_from_session(conn.private.phoenix_endpoint, session)

            authorizing = session_bool(authorizing)
            actor_paused = session_bool(actor_paused)

            conn
            |> Plug.Conn.put_session(:actor_resource, resource)
            |> Plug.Conn.put_session(:actor_domain, domain)
            |> Plug.Conn.put_session(:actor_action, action)
            |> Plug.Conn.put_session(:actor_primary_key, primary_key)
            |> Plug.Conn.put_session(:actor_authorizing, authorizing)
            |> Plug.Conn.put_session(:actor_paused, actor_paused)
            |> Plug.Conn.assign(:actor, actor)
            |> Plug.Conn.assign(:authorizing, authorizing || false)
            |> Plug.Conn.assign(:actor_paused, actor_paused)
            |> Plug.Conn.assign(:authorizing, authorizing)

          _ ->
            conn
        end
    end
  end

  defp session_bool(value) do
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
        false
    end
  end

  defp actor_resources(domains) do
    domains
    |> Enum.flat_map(fn domain ->
      domain
      |> Ash.Domain.Info.resources()
      |> Enum.filter(fn resource ->
        AshAdmin.Helpers.primary_action(resource, :read) && AshAdmin.Resource.actor?(resource)
      end)
      |> Enum.map(fn resource -> {domain, resource} end)
    end)
  end

  defp domains(otp_app) do
    otp_app
    |> Application.get_env(:ash_domains)
    |> Enum.filter(&AshAdmin.Domain.show?/1)
  end

  defp actor_domain_from_session(endpoint, %{"actor_domain" => domain}) do
    otp_app = endpoint.config(:otp_app)
    domains = Application.get_env(otp_app, :ash_domains)

    Enum.find(domains, fn allowed_domain ->
      AshAdmin.Domain.show?(allowed_domain) && AshAdmin.Domain.name(allowed_domain) == domain
    end)
  end

  defp actor_domain_from_session(_, _), do: nil

  defp actor_from_session(endpoint, %{
         "actor_resource" => resource,
         "actor_domain" => domain,
         "actor_primary_key" => primary_key,
         "actor_action" => action
       })
       when not is_nil(resource) and not is_nil(domain) do
    otp_app = endpoint.config(:otp_app)
    domains = Application.get_env(otp_app, :ash_domains)

    domain =
      Enum.find(domains, fn allowed_domain ->
        AshAdmin.Domain.show?(allowed_domain) && AshAdmin.Domain.name(allowed_domain) == domain
      end)

    resource =
      if domain do
        domain
        |> Ash.Domain.Info.resources()
        |> Enum.find(fn domain_resource ->
          AshAdmin.Resource.name(domain_resource) == resource
        end)
      end

    if domain && resource do
      action =
        if action do
          Ash.Resource.Info.action(resource, String.to_existing_atom(action), :read)
        end

      case decode_primary_key(resource, primary_key) do
        :error ->
          nil

        {:ok, filter} ->
          resource
          |> Ash.Query.filter(^filter)
          |> Ash.read_one!(action: action, authorize?: false, domain: domain)
      end
    end
  end

  defp actor_from_session(_, _), do: nil
end
