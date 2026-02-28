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
        if function_exported?(m, f, length(a)) do
          :dropdown
        else
          :typeahead
        end
    end
  end

  @doc false
  def list_tenants do
    {m, f, a} = Application.get_env(:ash_admin, :list_tenants)
    apply(m, f, a)
  end

  @doc false
  def search_tenants(search) do
    {m, f, a} = Application.get_env(:ash_admin, :list_tenants)
    apply(m, f, a ++ [search])
  end
end
