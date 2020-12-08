defmodule AshAdmin.Helpers do
  @moduledoc false

  def ash_admin_path(socket) do
    apply(socket.router.__helpers__(), :ash_admin_path, [socket, :page])
  end

  def self_path(url_path, socket_params, new_params) do
    url_path <>
      "?" <>
      Plug.Conn.Query.encode(Map.merge(socket_params || %{}, Enum.into(new_params, %{})))
  end

  def to_name(name) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def short_description(nil), do: {:not_split, nil}

  def short_description(description) do
    case String.split(description, ~r/\.(\n|$|\s)/, parts: 2) do
      [first, rest] ->
        {:split, first <> ".", rest}

      _ ->
        description
        |> String.split("\n", parts: 2)
        |> case do
          [first] ->
            {:not_split, first}

          [first, rest] ->
            {:split, first <> "\n", rest}

          _ ->
            {:not_split, nil}
        end
    end
  end

  @doc """
  TODO
  """
  def ash_admin_path(socket, api) do
    apply(
      socket.router.__helpers__(),
      String.to_atom(AshAdmin.Api.name(api) <> "_path"),
      [socket, :api_page]
    )
  end

  def ash_admin_path(socket, api, resource) do
    route = String.to_atom(AshAdmin.Api.name(api) <> AshAdmin.Resource.name(resource) <> "_path")

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page]
    )
  end

  def ash_action_path(socket, api, resource, action_type, action_name) do
    route =
      String.to_atom(
        AshAdmin.Api.name(api) <>
          AshAdmin.Resource.name(resource) <> "_#{action_type}" <> "_#{action_name}" <> "_path"
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page]
    )
  end

  def encode_primary_key(record) do
    record
    |> Map.take(Ash.Resource.primary_key(record.__struct__))
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  def decode_primary_key(string) do
    {:ok,
     string
     |> Base.decode64!()
     |> :erlang.binary_to_term([:safe])
     |> Map.to_list()}
  rescue
    _ ->
      :error
  end
end
