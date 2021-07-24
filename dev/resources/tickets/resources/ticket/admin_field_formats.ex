defmodule Demo.Tickets.Ticket.AdminFieldFormats do
  @moduledoc false
  def format_field(status, :description) do
    if status && String.length(status) > 20 do
      String.slice(status, 0, 20) <> "..."
    else
      status
    end
  end
end
