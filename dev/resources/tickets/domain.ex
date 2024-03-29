defmodule Demo.Tickets.Domain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(Demo.Tickets.Customer)
    resource(Demo.Tickets.Representative)
    resource(Demo.Tickets.Ticket)
    resource(Demo.Tickets.Comment)
    resource(Demo.Tickets.TicketLink)
    resource(Demo.Tickets.Organization)
  end
end
