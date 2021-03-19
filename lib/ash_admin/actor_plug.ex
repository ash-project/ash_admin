defmodule AshAdmin.ActorPlug do
  @behaviour Plug
  require Ash.Query

  import AshAdmin.Helpers

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.cookies do
      %{"actor_resource" => "undefined"} ->
        conn

      session ->
        actor_session(conn, session)
    end
  end

  def actor_session(
        conn,
        %{
          "actor_resource" => resource,
          "actor_api" => api,
          "actor_action" => action,
          "actor_primary_key" => primary_key
        } = session
      ) do
    authorizing = session["actor_authorizing"] || false

    actor_paused =
      if is_nil(session["actor_paused"]) do
        true
      else
        session["actor_paused"]
      end

    actor = actor_from_session(session)

    authorizing = session_bool(authorizing)
    actor_paused = session_bool(actor_paused)

    conn
    |> Plug.Conn.put_session(:actor_resource, resource)
    |> Plug.Conn.put_session(:actor_api, api)
    |> Plug.Conn.put_session(:actor_action, action)
    |> Plug.Conn.put_session(:actor_primary_key, primary_key)
    |> Plug.Conn.put_session(:actor_authorizing, authorizing)
    |> Plug.Conn.put_session(:actor_paused, actor_paused)
    |> Plug.Conn.assign(:actor, actor)
    |> Plug.Conn.assign(:authorizing, authorizing || false)
    |> Plug.Conn.assign(:actor_paused, actor_paused)
    |> Plug.Conn.assign(:authorizing, authorizing)
  end

  def actor_session(conn, _), do: conn

  def actor_from_session(%{
        "actor_resource" => resource,
        "actor_api" => api,
        "actor_primary_key" => primary_key,
        "actor_action" => action
      })
      when not is_nil(resource) and not is_nil(api) do
    resource = Module.concat([resource])
    api = Module.concat([api])

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
        |> api.read_one!(action: action)
    end
  end

  def actor_from_session(_), do: nil

  def session_bool(value) do
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
end
