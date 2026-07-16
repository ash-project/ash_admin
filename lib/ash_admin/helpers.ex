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

  def to_indexed_map(map) when is_map(map) and not is_struct(map) do
    map
    |> Enum.filter(fn {k, _v} -> digit_key?(k) end)
    |> Enum.map(fn {k, v} -> {String.to_integer(to_string(k)), v} end)
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

  # Strip LiveView `_unused_*` keys and keep only digit indexes for array maps.
  # Prevents polluted tag params from exploding into fake rows on phx-change.
  @doc false
  
  def sanitize_form_params(nil), do: nil

  def sanitize_form_params(params) when is_map(params) and not is_struct(params) do
    cleaned =
      params
      |> Enum.reject(fn {key, _value} -> unused_param?(key) end)
      |> Map.new(fn {key, value} -> {key, sanitize_form_params(value)} end)

    if indexed_array_map?(cleaned) do
      to_indexed_map(cleaned)
    else
      cleaned
    end
  end

  def sanitize_form_params(params) when is_list(params) do
    Enum.map(params, &sanitize_form_params/1)
  end

  def sanitize_form_params(other), do: other




  # FilterForm.Arguments casts indexed maps as keys; convert array args to lists first.
  @doc false
  def normalize_argument_params(params, arguments) when is_map(params) and is_list(arguments) do
    params = sanitize_form_params(params)

    Enum.reduce(arguments, params, fn argument, acc ->
      name = to_string(argument.name)

      case {Map.get(acc, name), argument.type} do
        {value, {:array, _}} when is_map(value) and not is_struct(value) ->
          Map.put(acc, name, indexed_map_values(value))

        _ ->
          acc
      end
    end)
  end

  def normalize_argument_params(params, _arguments), do: params





  defp indexed_map_values(map) do
    map
    |> to_indexed_map()
    |> Enum.sort_by(fn {key, _} -> String.to_integer(key) end)
    |> Enum.map(&elem(&1, 1))
  end

  defp unused_param?(key), do: String.starts_with?(to_string(key), "_unused_")

  defp digit_key?(key), do: String.match?(to_string(key), ~r/^[0-9]+$/)

  defp indexed_array_map?(map) when map_size(map) == 0, do: false

  defp indexed_array_map?(map) do
    Enum.all?(Map.keys(map), &digit_key?/1)
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
