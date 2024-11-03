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
    |> Enum.sort_by(fn {label, _items} -> label || "_____always_put_me_last" end)
    |> Keyword.values()
  end

  def dropdown_group_labels(domain) do
    AshAdmin.Domain.resource_group_labels(domain)
  end
end
