# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Helpers.FormatHelper do
  @moduledoc false

  def format_attribute(formats, record, attribute) do
    default = default_formatter(attribute)
    {mod, func, args} = Keyword.get(formats || [], attribute.name, default)

    record
    |> Map.get(attribute.name)
    |> then(&apply(mod, func, [&1] ++ args))
  end

  @doc false
  def format_array(nil), do: ""
  def format_array([]), do: ""

  def format_array(list) when is_list(list) do
    iodata =
      list
      |> Enum.map(&item_to_iodata/1)
      |> Enum.intersperse(", ")

    {:safe, iodata}
  end

  def format_array(other), do: Phoenix.HTML.Safe.to_iodata(other)

  defp default_formatter(%{type: {:array, _}}), do: {__MODULE__, :format_array, []}
  defp default_formatter(_), do: {Phoenix.HTML.Safe, :to_iodata, []}

  defp item_to_iodata(item) when is_binary(item), do: Phoenix.HTML.Safe.to_iodata(item)
  defp item_to_iodata(item) when is_list(item), do: Phoenix.HTML.Safe.to_iodata(inspect(item))

  defp item_to_iodata(item) do
    Phoenix.HTML.Safe.to_iodata(item)
  rescue
    _ -> Phoenix.HTML.Safe.to_iodata(inspect(item))
  end
end
