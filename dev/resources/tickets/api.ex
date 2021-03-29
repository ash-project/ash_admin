defmodule Demo.Tickets.Api do
  @moduledoc false
  use Ash.Api

  alias Demo.Tickets.{Comment, Customer, Representative, Ticket, TicketLink, Organization}

  resources do
    resource(Customer)
    resource(Representative)
    resource(Ticket)
    resource(Comment)
    resource(TicketLink)
    resource(Organization)
  end
end
