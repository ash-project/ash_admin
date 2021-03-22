defmodule Demo.Tickets.Api do
  @moduledoc false
  use Ash.Api

  alias Demo.Tickets.{Comment, Customer, Representative, Ticket}

  resources do
    resource(Customer)
    resource(Representative)
    resource(Ticket)
    resource(Comment)
  end
end
