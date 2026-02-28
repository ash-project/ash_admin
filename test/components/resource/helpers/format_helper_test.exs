# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.Helpers.FormatHelperTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Components.Resource.Helpers.FormatHelper

  describe "format_attribute/3" do
    setup do
      formats = [expires_at: {AshAdmin.Test.Post.AdminFieldFormats, :format_field, [:expires_at]}]

      record =
        AshAdmin.Test.Post
        |> Ash.Changeset.for_create(:create, %{
          body: "Welcome!",
          expires_at: ~U[2024-11-09 19:49:30.885627Z]
        })
        |> Ash.create!()

      attribute =
        AshAdmin.Test.Post
        |> Ash.Resource.Info.attributes()
        |> Enum.find(&(&1.name == :expires_at))

      %{formats: formats, record: record, attribute: attribute}
    end

    test "format without given formats", %{record: record, attribute: attribute} do
      assert "2024-11-09T19:49:30.885627Z" == FormatHelper.format_attribute([], record, attribute)
    end

    test "format with given formats", %{formats: formats, record: record, attribute: attribute} do
      assert "2024-11-09 19:49:30.885627" ==
               FormatHelper.format_attribute(formats, record, attribute)
    end
  end
end
