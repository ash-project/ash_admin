defmodule Demo.Tickets.Api do
  use Ash.Api

  alias Demo.Tickets.{Customer, Representative, Ticket}

  resources do
    resource(Customer)
    resource(Representative)
    resource(Ticket)
  end
end
