# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Field do
  @moduledoc """
  The representation of a configured field in the admin UI.
  """
  defstruct [:name, :type, :default, :max_file_size, :accepted_extensions, :__spark_metadata__]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "The name of the field to be modified"
    ],
    type: [
      type: {:in, [:default, :long_text, :short_text, :markdown]},
      required: false,
      doc:
        "The type of the value in the form. Use `default` if you are just specifying field order"
    ],
    max_file_size: [
      type: :integer,
      required: false,
      doc:
        "The maximum file size in bytes to allow to be uploaded. Only applicable to action arguments of `Ash.Type.File`."
    ],
    accepted_extensions: [
      type: {:or, [:any, {:list, :string}]},
      required: false,
      doc:
        "A list of unique file extensions (such as \".jpeg\") or mime type (such as \"image/jpeg\" or \"image/*\"). Only applicable to action arguments of `Ash.Type.File`."
    ]
  ]

  def schema, do: @schema
end
