defmodule Demo.Tickets.Api do
  @moduledoc false
  use Ash.Api

  alias Demo.Tickets.{Comment, Customer, Representative, Ticket, TicketLink}

  resources do
    resource(Customer)
    resource(Representative)
    resource(Ticket)
    resource(Comment)
    resource(TicketLink)
  end
end
