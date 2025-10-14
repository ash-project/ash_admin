# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Errors.NotFound do
  defexception [:thing, :key]

  def message(error) do
    "#{error.thing} #{error.key} not found"
  end

  defimpl Plug.Exception do
    def status(_), do: 404
    def actions(_), do: []
  end
end
