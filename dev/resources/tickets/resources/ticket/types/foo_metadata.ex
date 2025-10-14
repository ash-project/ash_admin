# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
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
