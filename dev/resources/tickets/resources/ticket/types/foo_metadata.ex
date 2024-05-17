defmodule Demo.Tickets.Ticket.Types.FooMetadata do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :foo, :integer do
      public? true
    end
  end
end
