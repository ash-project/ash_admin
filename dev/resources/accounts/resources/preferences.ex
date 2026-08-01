# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Demo.Accounts.Preferences do
  @moduledoc """
  A plain Elixir struct used to exercise the `Ash.Type.Struct` render path in AshAdmin.
  """
  use Ash.TypedStruct

  typed_struct do
    field :theme, :atom, default: :system, constraints: [one_of: [:light, :dark, :system]]
    field :locale, :string, default: "en-US"
  end
end
