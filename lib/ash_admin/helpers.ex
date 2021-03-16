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
      String.to_atom(String.downcase(AshAdmin.Api.name(api) <> "_path")),
      [socket, :api_page]
    )
  end

  def ash_admin_path(socket, api, resource) do
    route =
      String.to_atom(
        String.downcase(AshAdmin.Api.name(api) <> AshAdmin.Resource.name(resource) <> "_path")
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page]
    )
  end

  def ash_create_path(socket, api, resource) do
    route =
      String.to_atom(
        String.downcase(
          AshAdmin.Api.name(api) <> AshAdmin.Resource.name(resource) <> "create_path"
        )
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page]
    )
  end

  def ash_update_path(socket, api, resource, record) do
    route =
      String.to_atom(
        String.downcase(
          AshAdmin.Api.name(api) <> AshAdmin.Resource.name(resource) <> "update_path"
        )
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page, encode_primary_key(record)]
    )
  end

  def ash_update_path(socket, api, resource, record, action_name) do
    route =
      String.to_atom(
        String.downcase(
          AshAdmin.Api.name(api) <>
            AshAdmin.Resource.name(resource) <> to_string(action_name) <> "update_path"
        )
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page, encode_primary_key(record)]
    )
  end

  def ash_action_path(socket, api, resource, action_type, action_name) do
    route =
      String.to_atom(
        String.downcase(
          AshAdmin.Api.name(api) <>
            AshAdmin.Resource.name(resource) <> "_#{action_type}" <> "_#{action_name}" <> "_path"
        )
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :resource_page]
    )
  end

  def ash_show_path(socket, api, resource, record, action_name) do
    route =
      String.to_atom(
        String.downcase(
          AshAdmin.Api.name(api) <>
            AshAdmin.Resource.name(resource) <> "_show" <> "_#{action_name}" <> "_path"
        )
      )

    apply(
      socket.router.__helpers__(),
      route,
      [socket, :show_page, encode_primary_key(record)]
    )
  end

  def encode_primary_key(record) do
    pkey = Ash.Resource.Info.primary_key(record.__struct__)

    if Enum.count(pkey) == 1 and simple_type?(record.__struct__, Enum.at(pkey, 0)) do
      Map.get(record, Enum.at(pkey, 0))
    else
      record
      |> Map.take(pkey)
      |> :erlang.term_to_binary()
      |> Base.encode64()
    end
  end

  def decode_primary_key(resource, string) do
    pkey = Ash.Resource.Info.primary_key(resource)

    if Enum.count(pkey) == 1 and simple_type?(resource, Enum.at(pkey, 0)) do
      {:ok, [{Enum.at(pkey, 0), string}]}
    else
      {:ok,
       string
       |> Base.decode64!()
       |> :erlang.binary_to_term([:safe])
       |> Map.to_list()}
    end
  rescue
    _ ->
      :error
  end

  @simple_types [
    Ash.Type.String,
    Ash.Type.UUID
  ]

  defp simple_type?(resource, field) do
    Ash.Resource.Info.attribute(resource, field).type in @simple_types
  end
end
