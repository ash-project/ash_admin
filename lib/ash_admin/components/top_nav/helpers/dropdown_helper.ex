# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.DropdownHelper do
  @moduledoc false

  def dropdown_groups(prefix, current_resource, domain) do
    group_order =
      domain
      |> AshAdmin.Domain.resource_group_labels()
      |> Enum.with_index()
      |> Map.new(fn {{group, _label}, index} -> {group, index} end)

    for resource <- AshAdmin.Domain.show_resources(domain) do
      %{
        text: AshAdmin.Resource.name(resource),
        to:
          "#{prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}",
        active: resource == current_resource,
        group: AshAdmin.Resource.resource_group(resource)
      }
    end
    |> Enum.group_by(fn resource -> resource.group end)
    |> Enum.sort_by(fn
      {nil, _links} -> {1, 0}
      {group, _links} -> {0, Map.get(group_order, group, map_size(group_order))}
    end)
    |> Enum.map(fn {_group, links} -> links end)
  end

  def dropdown_group_labels(domain) do
    AshAdmin.Domain.resource_group_labels(domain)
  end
end
