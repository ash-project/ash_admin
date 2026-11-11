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

  @doc """
  Builds an admin URL, URL-encoding every query parameter. User-controlled
  values (e.g. string primary keys) must not be interpolated raw, or they can
  inject extra query parameters and retarget the link.
  """
  def admin_path(prefix, params) do
    query =
      params
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {k, to_string(v)} end)
      |> URI.encode_query()

    prefix <> "?" <> query
  end

  @doc """
  Resolves where the admin shows the destination of `relationship`, as a map of
  `:domain`, `:resource`, `:table` and the `:relationship` name, or returns `nil`
  when the destination can't be opened in this admin.

  `domains` is the list of domains the admin shows (its `:ash_domains`). A link
  to any other domain would silently open the first shown domain instead.
  """
  def relationship_target(relationship, current_domain, domains) do
    destination = relationship.destination
    domain = destination_domain(relationship, current_domain)

    if visible_resource?(domain, destination, domains) do
      %{
        domain: domain,
        resource: destination,
        table: relationship.context[:data_layer][:table],
        relationship: relationship.name
      }
    end
  end

  @doc """
  Returns the domain of the destination of `relationship`: the relationship's own
  `domain`, else the destination resource's domain, else `current_domain`.
  """
  def destination_domain(relationship, current_domain) do
    relationship.domain || Ash.Resource.Info.domain(relationship.destination) || current_domain
  end

  @doc """
  Returns the admin show path of `record` at a target from `relationship_target/3`.
  """
  def record_path(prefix, %{domain: domain, resource: resource, table: table}, record) do
    admin_path(prefix,
      domain: AshAdmin.Domain.name(domain),
      resource: AshAdmin.Resource.name(resource),
      table: table,
      primary_key: encode_primary_key(record),
      action_type: "read"
    )
  end

  @doc """
  Returns a map of the `belongs_to` foreign key attributes of `resource` that
  should link to the related record, to their target (see `relationship_target/3`).

  Empty when the resource sets `link_relationships?` to `false`.

  `auth_opts` holds the `:actor`, `:tenant` and `:authorize?` of the page. When
  `:authorize?` is true, a destination the actor can't read is left out, so its
  key renders as plain text and the related record isn't loaded. Loading it
  would make a policy that forbids the read outright fail the whole read.

  Resolve it once per resource and look attributes up in it, instead of
  resolving it for every rendered value.
  """
  def foreign_key_targets(resource, current_domain, domains, auth_opts) do
    if AshAdmin.Resource.link_relationships?(resource) do
      resource
      |> Ash.Resource.Info.relationships()
      |> Enum.filter(&(&1.type == :belongs_to))
      |> Enum.flat_map(fn relationship ->
        with %{} = target <- relationship_target(relationship, current_domain, domains),
             true <- can_read_related?(relationship, target.domain, auth_opts) do
          [{relationship.source_attribute, target}]
        else
          _ -> []
        end
      end)
      |> Map.new()
    else
      %{}
    end
  end

  # Loading a relationship reads its destination with the relationship's read
  # action, or the primary read action. A `:maybe` answer (e.g. a filter policy)
  # counts as readable: the load then filters the record out instead of failing.
  defp can_read_related?(relationship, domain, auth_opts) do
    if auth_opts[:authorize?] do
      destination = relationship.destination

      action =
        relationship.read_action ||
          case Ash.Resource.Info.primary_action(destination, :read) do
            %{name: name} -> name
            nil -> nil
          end

      # `Ash.can/3` rejects a `:domain` option, so the query carries it.
      not is_nil(action) and
        match?(
          {:ok, allowed} when allowed != false,
          destination
          |> Ash.Query.new(domain: domain)
          |> Ash.Query.set_tenant(auth_opts[:tenant])
          |> Ash.Query.for_read(action, %{}, actor: auth_opts[:actor])
          |> Ash.can(auth_opts[:actor], maybe_is: :maybe)
        )
    else
      true
    end
  end

  @doc """
  Returns the load statement that fetches the related records of `targets`
  (from `foreign_key_targets/4`), selecting only their primary key.

  The foreign key doesn't have to reference the destination's primary key, so
  the link is built from the loaded record rather than from the key's value.
  """
  def link_load(targets) do
    targets
    |> Map.values()
    |> Enum.map(fn %{relationship: name, resource: resource} ->
      {name, Ash.Query.select(resource, [])}
    end)
  end

  @doc """
  Returns the load statement for `relationship` of `resource` that also loads
  the related records' own linked `belongs_to` relationships (see
  `link_load/1`).

  Only the foreign keys that the show page of `resource` renders for the
  relationship are loaded: those in its `show_relationship_fields`, if set, and
  never the key of a to-many relationship that points back to `resource`.
  """
  def relationship_load(resource, relationship, current_domain, domains, auth_opts) do
    destination = relationship.destination
    domain = destination_domain(relationship, current_domain)
    fields = AshAdmin.Resource.show_relationship_fields(resource, relationship.name)

    skip =
      if relationship.cardinality == :many, do: [relationship.destination_attribute], else: []

    destination
    |> foreign_key_targets(domain, domains, auth_opts)
    |> Map.filter(fn {attribute, _} ->
      attribute not in skip and (is_nil(fields) or attribute in fields)
    end)
    |> link_load()
    |> case do
      [] -> relationship.name
      link_load -> {relationship.name, Ash.Query.load(destination, link_load)}
    end
  end

  @doc """
  Returns the admin show path of the record `record` references through the
  foreign key of `target`, or `nil` when there is no target or the related
  record isn't loaded (see `link_load/1`).
  """
  def foreign_key_path(_prefix, nil, _record), do: nil
  def foreign_key_path(nil, _target, _record), do: nil

  def foreign_key_path(prefix, %{relationship: name, resource: resource} = target, record) do
    case Map.get(record, name) do
      %^resource{} = related -> record_path(prefix, target, related)
      _ -> nil
    end
  end

  defp visible_resource?(domain, resource, domains) when is_list(domains) do
    domain in domains and AshAdmin.Domain.show?(domain) and
      resource in AshAdmin.Domain.show_resources(domain) and
      not is_nil(AshAdmin.Resource.show_action(resource))
  end

  defp visible_resource?(_domain, _resource, _domains), do: false

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

  # A composite primary key encodes to at most a handful of scalar values, so a
  # legitimate param is tiny. This bounds the decode against a memory-inflation
  # payload; override with `config :ash_admin, :max_primary_key_byte_size, n`.
  @default_max_primary_key_byte_size 10_240

  def decode_primary_key(resource, string) do
    pkey = Ash.Resource.Info.primary_key(resource)

    if Enum.count(pkey) == 1 and simple_type?(resource, Enum.at(pkey, 0)) do
      {:ok, [{Enum.at(pkey, 0), string}]}
    else
      max_byte_size =
        Application.get_env(
          :ash_admin,
          :max_primary_key_byte_size,
          @default_max_primary_key_byte_size
        )

      with {:ok, decoded} <- Base.decode64(string),
           :ok <- check_primary_key_size(decoded, max_byte_size),
           term <- Ash.Helpers.non_executable_binary_to_term(decoded, [:safe]),
           :ok <- check_no_expression(term),
           :ok <- check_primary_key_fields(term, pkey) do
        {:ok, Map.to_list(term)}
      else
        _ -> :error
      end
    end
  rescue
    _ ->
      :error
  end

  # Ash only ever encodes primary keys with uncompressed `:erlang.term_to_binary/1`,
  # so a compressed payload (external term format tag `80`) is never legitimate.
  # Rejecting it removes the decompression-bomb vector; uncompressed payloads are
  # then bounded directly by their own byte size.
  # A composite primary key must decode to a plain map whose keys are all real
  # primary-key fields. Without this an attacker can encode a map of any
  # attribute (e.g. %{api_token: "guess"}) and turn the record lookup into an
  # equality oracle over sensitive fields; a struct term also injects a bogus
  # `__struct__` key.
  defp check_primary_key_fields(term, pkey) when is_map(term) and not is_struct(term) do
    keys = Map.keys(term)

    if keys != [] and Enum.all?(keys, &(&1 in pkey)) do
      :ok
    else
      :error
    end
  end

  defp check_primary_key_fields(_term, _pkey), do: :error

  defp check_primary_key_size(<<131, 80, _::binary>>, _max), do: :error
  defp check_primary_key_size(binary, max) when byte_size(binary) > max, do: :error
  defp check_primary_key_size(_binary, _max), do: :ok

  # A legitimate encoded primary key only ever contains scalar values. A decoded
  # term that is or contains an Ash expression (e.g. `%Ash.Query.Call{}`) is a
  # forged param attempting to inject a filter expression that would be spliced
  # into the query and evaluated (SQL injection / RCE depending on the data
  # layer). Reject any such term outright.
  defp check_no_expression(term) do
    if Ash.Expr.expr?(term) do
      :error
    else
      :ok
    end
  end

  @simple_types [
    Ash.Type.String,
    Ash.Type.UUID,
    Ash.Type.UUIDv7
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

  @doc false
  # The resources the dashboard user can pick an actor from, as `{domain, resource}` pairs.
  def actor_resources(domains) do
    for domain <- domains,
        resource <- AshAdmin.Domain.show_resources(domain),
        primary_action(resource, :read) && AshAdmin.Resource.actor?(resource),
        do: {domain, resource}
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
