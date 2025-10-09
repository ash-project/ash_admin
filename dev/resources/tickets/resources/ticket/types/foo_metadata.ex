# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Ticket.Types.FooMetadata do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :foo, :integer do
      public? true
    end
  end
end
