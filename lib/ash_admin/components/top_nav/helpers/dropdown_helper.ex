# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.DropdownHelper do
  @moduledoc false

  @doc """
  Groups the domain's resources for the top navigation dropdown.

  Groups are ordered as given in `resource_group_labels`. Groups without a
  label follow in the order their resources are declared, and resources
  without a group come last.
  """
  def dropdown_groups(prefix, current_resource, domain) do
    links =
      for resource <- AshAdmin.Domain.show_resources(domain) do
        %{
          text: AshAdmin.Resource.name(resource),
          to:
            "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}",
          active: resource == current_resource,
          group: AshAdmin.Resource.resource_group(resource)
        }
      end

    label_order =
      domain
      |> AshAdmin.Domain.resource_group_labels()
      |> Keyword.keys()
      |> Enum.with_index()
      |> Map.new()

    declaration_order =
      links
      |> Enum.map(& &1.group)
      |> Enum.uniq()
      |> Enum.with_index()
      |> Map.new()

    links
    |> Enum.group_by(& &1.group)
    |> Enum.sort_by(fn
      {nil, _links} ->
        {2, 0}

      {group, _links} ->
        case Map.fetch(label_order, group) do
          {:ok, index} -> {0, index}
          :error -> {1, Map.fetch!(declaration_order, group)}
        end
    end)
    |> Enum.map(fn {_group, links} -> links end)
  end

  def dropdown_group_labels(domain) do
    AshAdmin.Domain.resource_group_labels(domain)
  end
end
