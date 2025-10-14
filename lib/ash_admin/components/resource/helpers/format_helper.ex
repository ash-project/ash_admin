# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Helpers.FormatHelper do
  @moduledoc false

  def format_attribute(formats, record, attribute) do
    {mod, func, args} =
      Keyword.get(formats || [], attribute.name, {Phoenix.HTML.Safe, :to_iodata, []})

    record
    |> Map.get(attribute.name)
    |> then(&apply(mod, func, [&1] ++ args))
  end
end
