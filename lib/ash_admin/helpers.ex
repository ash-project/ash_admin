defmodule AshAdmin.Helpers do
  @moduledoc false

  def ash_admin_path(socket) do
    apply(socket.router.__helpers__(), :ash_admin_path, [socket, :page])
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
