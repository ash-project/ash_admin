# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Ticket.AdminFieldFormats do
  @moduledoc false
  def format_field(status, :description) do
    if status && String.length(status) > 20 do
      String.slice(status, 0, 20) <> "..."
    else
      status
    end
  end

  def format_field(datetime, field) when field in [:inserted_at, :updated_at],
    do: Calendar.strftime(datetime, "%c.%f")
end
