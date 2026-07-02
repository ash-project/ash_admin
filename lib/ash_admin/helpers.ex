# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Helpers do
  @moduledoc false

  def classes(list) when is_list(list) do
    Enum.flat_map(list, &classes/1)
  end

  def classes(string) when is_binary(string) do
    [string]
  end

  def classes(atom) when is_atom(atom) do
    [to_string(atom)]
  end

  def classes({classes, true}) do
    classes(classes)
  end

  def classes({_, _}), do: []

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

  def to_name(%{__struct__: Ash.Resource.Attribute, related_resource: resource} = attribute)
      when not is_nil(resource) do
    if _label_field = AshAdmin.Resource.label_field(resource) do
      attribute.name
      |> to_string()
      |> String.replace_suffix("_id", "")
      |> to_name()
    else
      to_name(attribute.name)
    end
  end

  def to_name(%{name: name}) do
    name
    |> to_string()
    |> to_name()
  end

  def to_name(name) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def sensitive?(%{sensitive?: true}) do
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

  # Array reordering helpers for Sortable.js drag-and-drop in admin forms

  # normalize a list or map into a dense string-indexed map (%{"0" => ..., "1" => ...})
  @doc false
  def to_indexed_map(nil), do: %{}

  def to_indexed_map(map) when is_map(map) do
    map
    |> Enum.filter(fn {k, _v} -> String.match?(k, ~r/^[0-9]+$/) end)
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    |> to_indexed_map()
  end

  def to_indexed_map(list) when is_list(list) do
    list
    |> Enum.with_index()
    |> Map.new(fn {value, index} -> {to_string(index), value} end)
  end

  def to_indexed_map(other) do
    other |> List.wrap() |> to_indexed_map()
  end

  # reorder values by original indices in their new order (e.g. ["1", "0"] swaps two items)
  @doc false
  def reorder_by_indices(value, indices) when is_list(indices) do
    indexed = to_indexed_map(value)

    indices
    |> Enum.map(&to_string/1)
    |> Enum.map(&Map.get(indexed, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Map.new(fn {value, index} -> {to_string(index), value} end)
  end

  def primary_action(resource, type) do
    actions =
      case type do
        :update -> AshAdmin.Resource.update_actions(resource)
        :destroy -> AshAdmin.Resource.destroy_actions(resource)
        :read -> AshAdmin.Resource.read_actions(resource)
        :create -> AshAdmin.Resource.create_actions(resource)
      end

    primary_action = Ash.Resource.Info.primary_action(resource, type)

    case actions do
      actions when is_list(actions) ->
        if primary_action && primary_action.name in actions do
          primary_action
        else
          Ash.Resource.Info.action(resource, Enum.at(actions, 0))
        end

      _ ->
        primary_action || Ash.Resource.Info.actions(resource) |> Enum.find(&(&1.type == type))
    end
  end
end
