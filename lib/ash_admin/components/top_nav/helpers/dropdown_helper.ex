# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.DropdownHelper do
  @moduledoc false

  def dropdown_groups(prefix, current_resource, domain) do
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
    |> Enum.with_index()
    |> Enum.sort_by(fn
      {{nil, _links}, _index} -> {1, nil}
      {{_group, _links}, index} -> {0, index}
    end)
    |> Enum.map(fn {{_group, links}, _index} -> links end)
  end

  def dropdown_group_labels(domain) do
    AshAdmin.Domain.resource_group_labels(domain)
  end
end
