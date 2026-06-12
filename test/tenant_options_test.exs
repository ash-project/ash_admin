# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.TenantOptionsTest do
  use ExUnit.Case, async: false

  defmodule Tenants do
    def list_tenants do
      ["tenant_a", %{label: "Dev Lab", value: 1}]
    end

    def search_tenants(search) do
      [%{label: "#{search} Lab", value: search}]
    end
  end

  setup do
    previous = Application.get_env(:ash_admin, :list_tenants)

    on_exit(fn ->
      if previous do
        Application.put_env(:ash_admin, :list_tenants, previous)
      else
        Application.delete_env(:ash_admin, :list_tenants)
      end
    end)
  end

  test "normalizes values and atom-keyed label/value tenant options" do
    assert AshAdmin.normalize_tenant_options([
             "tenant_a",
             %{label: "Dev Lab", value: 1}
           ]) == [
             %{label: "tenant_a", value: "tenant_a"},
             %{label: "Dev Lab", value: "1"}
           ]
  end

  test "list_tenants returns normalized label/value tenant options" do
    Application.put_env(:ash_admin, :list_tenants, {Tenants, :list_tenants, []})

    assert AshAdmin.list_tenants() == [
             %{label: "tenant_a", value: "tenant_a"},
             %{label: "Dev Lab", value: "1"}
           ]
  end

  test "search_tenants returns normalized label/value tenant options" do
    Application.put_env(:ash_admin, :list_tenants, {Tenants, :search_tenants, []})

    assert AshAdmin.search_tenants("Dev") == [%{label: "Dev Lab", value: "Dev"}]
  end
end
