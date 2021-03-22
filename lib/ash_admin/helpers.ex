defmodule AshAdmin.Helpers do
  @moduledoc false

  def replace_all_loaded(resource, data \\ nil) do
    managed = AshAdmin.Resource.manage_related(resource) || []

    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(fn relationship ->
      is_nil(data) ||
        not match?(%Ash.NotLoaded{}, Map.get(data, relationship.name))
    end)
    |> Enum.map(fn rel ->
      if rel.name in managed do
        {rel.name,
         {:manage,
          on_lookup: :relate,
          on_no_match: :create,
          on_match: :update,
          on_missing: :destroy,
          authorize?: true,
          meta: [
            id: rel.name
          ]}}
      else
        {rel.name,
         {:manage,
          on_lookup: :relate,
          on_no_match: :error,
          on_match: :ignore,
          on_missing: :unrelate,
          authorize?: true,
          meta: [
            id: rel.name
          ]}}
      end
    end)
  end

  def set_table(changeset_or_query, nil), do: changeset_or_query

  def set_table(%Ash.Query{} = query, table) do
    Ash.Query.set_context(query, %{data_layer: %{table: table}})
  end

  def set_table(%Ash.Changeset{} = changeset, table) do
    Ash.Changeset.set_context(changeset, %{data_layer: %{table: table}})
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

  defp prefix(nil, path), do: path
  defp prefix(prefix, path), do: prefix <> path

  def ash_admin_path(prefix) do
    prefix(prefix, "/")
  end

  def ash_admin_path(prefix, api) do
    prefix(prefix, "/#{AshAdmin.Api.name(api)}")
  end

  def ash_admin_path(prefix, api, resource) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}"
    )
  end

  def ash_create_path(prefix, api, resource) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/create"
    )
  end

  def ash_create_path(prefix, api, resource, action_name, nil) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/create/#{action_name}"
    )
  end

  def ash_create_path(prefix, api, resource, action_name, table) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{table}/create/#{
        action_name
      }"
    )
  end

  def ash_update_path(prefix, api, resource, record) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/update/#{
        encode_primary_key(record)
      }"
    )
  end

  def ash_update_path(prefix, api, resource, record, action_name, nil) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/update/#{action_name}/#{
        encode_primary_key(record)
      }"
    )
  end

  def ash_update_path(prefix, api, resource, record, action_name, table) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{table}/update/#{
        action_name
      }/#{encode_primary_key(record)}"
    )
  end

  def ash_destroy_path(prefix, api, resource, record) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/destroy/#{
        encode_primary_key(record)
      }"
    )
  end

  def ash_destroy_path(prefix, api, resource, record, action_name, nil) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/destroy/#{action_name}/#{
        encode_primary_key(record)
      }"
    )
  end

  def ash_destroy_path(prefix, api, resource, record, action_name, table) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{table}/destroy/#{
        action_name
      }#{encode_primary_key(record)}"
    )
  end

  def ash_action_path(prefix, api, resource, action_type, action_name, nil) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{action_type}/#{
        action_name
      }"
    )
  end

  def ash_action_path(prefix, api, resource, action_type, action_name, table) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{table}/#{action_type}/#{
        action_name
      }"
    )
  end

  # sobelow_skip ["DOS.StringToAtom"]
  def ash_show_path(prefix, api, resource, record, nil) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/show/#{
        encode_primary_key(record)
      }"
    )
  end

  def ash_show_path(prefix, api, resource, record, table) do
    prefix(
      prefix,
      "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{table}/show/#{
        encode_primary_key(record)
      }"
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
