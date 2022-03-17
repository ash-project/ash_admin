defmodule Demo.Tickets.Registry do
  use Ash.Registry
  alias Demo.Tickets.{Comment, Customer, Representative, Ticket, TicketLink, Organization}

  entries do
    entry(Customer)
    entry(Representative)
    entry(Ticket)
    entry(Comment)
    entry(TicketLink)
    entry(Organization)
  end
end
