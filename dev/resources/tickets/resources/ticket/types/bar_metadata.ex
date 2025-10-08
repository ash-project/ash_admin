# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Ticket.Types.BarMetadata do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :bar, :string do
      public? true
    end
  end
end
