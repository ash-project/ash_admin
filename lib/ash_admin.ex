# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin do
  @moduledoc false

  @doc false
  def tenant_mode do
    case Application.get_env(:ash_admin, :list_tenants) do
      nil ->
        :text

      {m, f, a} when is_list(a) ->
        if Code.ensure_loaded?(m) && function_exported?(m, f, length(a)) do
          :dropdown
        else
          :typeahead
        end
    end
  end

  @doc false
  def list_tenants do
    {m, f, a} = Application.get_env(:ash_admin, :list_tenants)

    m
    |> apply(f, a)
    |> normalize_tenant_options()
  end

  @doc false
  def search_tenants(search) do
    {m, f, a} = Application.get_env(:ash_admin, :list_tenants)

    m
    |> apply(f, a ++ [search])
    |> normalize_tenant_options()
  end

  @doc false
  def normalize_tenant_options(options) do
    Enum.map(options, &normalize_tenant_option/1)
  end

  defp normalize_tenant_option(%{label: label, value: value}) do
    %{label: to_string(label), value: to_string(value)}
  end

  defp normalize_tenant_option(value) do
    value = to_string(value)
    %{label: value, value: value}
  end
end
