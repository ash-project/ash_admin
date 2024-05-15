defmodule Demo.Tickets.Domain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
    show_resources [
      Demo.Tickets.Customer,
      Demo.Tickets.Representative,
      Demo.Tickets.Ticket,
      Demo.Tickets.Comment,
      Demo.Tickets.Organization
    ]
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
