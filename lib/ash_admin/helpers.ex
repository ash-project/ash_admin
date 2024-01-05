defmodule AshAdmin.Helpers do
  @moduledoc false

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

  def to_name(:id), do: "ID"

  def to_name(name) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def sensitive?(%Ash.Resource.Attribute{sensitive?: true}) do
    true
  end

  def sensitive?(_) do
    false
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

  def primary_action(resource, type) do
    case Ash.Resource.Info.primary_action(resource, type) do
      nil ->
        Ash.Resource.Info.actions(resource) |> Enum.find(&(&1.type == type))

      other ->
        other
    end
  rescue
    _ ->
      Ash.Resource.Info.actions(resource) |> Enum.find(&(&1.type == type))
  end
end
