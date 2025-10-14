# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Post.AdminFieldFormats do
  @moduledoc false

  def format_field(datetime, field) when field in [:expires_at],
    do: Calendar.strftime(datetime, "%c.%f")
end
