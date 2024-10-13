defmodule AshAdmin.Resource.Field do
  @moduledoc """
  The representation of a configured field in the admin UI.
  """
  defstruct [:name, :type, :default, :options]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "The name of the field to be modified"
    ],
    type: [
      type: {:in, [:default, :long_text, :short_text, :markdown, :select]},
      required: true,
      doc:
        "The type of the value in the form. Use `default` if you are just specifying field order"
    ],
    options: [
      required: false,
      doc: "Options to pass to the form field"
    ]
  ]

  def schema, do: @schema
end
