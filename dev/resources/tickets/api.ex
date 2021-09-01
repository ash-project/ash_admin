defmodule Demo.Tickets.Api do
  @moduledoc false
  use Ash.Api,
    extensions: [AshAdmin.Api]

  alias Demo.Tickets.{Comment, Customer, Representative, Ticket, TicketLink, Organization}

  admin do
    show? true
  end

  resources do
    resource(Customer)
    resource(Representative)
    resource(Ticket)
    resource(Comment)
    resource(TicketLink)
    resource(Organization)
  end
end
