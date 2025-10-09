# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule Demo.Tickets.Ticket.Types.Metadata do
  use Ash.Type.NewType, subtype_of: :union, constraints: [
    types: [
      foo: [
        type: Demo.Tickets.Ticket.Types.FooMetadata,
        tag: :type,
        tag_value: :foo
      ],
      bar: [
        type: Demo.Tickets.Ticket.Types.BarMetadata,
        tag: :type,
        tag_value: :bar
      ],
      string: [
        type: :string
      ]
    ]
  ]
end
