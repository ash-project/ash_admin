# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Calculations.Concat do
  use Ash.Resource.Calculation

  @impl true
  def init(opts) do
    if opts[:keys] && is_list(opts[:keys]) && Enum.all?(opts[:keys], &is_atom/1) do
      {:ok, opts}
    else
      {:error, "Expected a `keys` option for which keys to concat"}
    end
  end

  @impl true
  def load(_query, opts, _context) do
    opts[:keys]
  end

  @impl true
  def calculate(records, opts, %{arguments: %{separator: separator}}) when is_bitstring(separator) do
    Enum.map(records, fn record ->
      Enum.map_join(opts[:keys], separator, fn key ->
        to_string(Map.get(record, key))
      end)
    end)
  end

  def calculate(_records, _opts, _context) do
    {:error, "Argument separator invalid"}
  end
end
