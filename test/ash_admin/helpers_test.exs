# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.HelpersTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Helpers

  # unit tests for array reordering helpers used by Sortable.js drag-and-drop
  describe "to_indexed_map/1" do
    test "converts a list to a string-indexed map" do
      assert Helpers.to_indexed_map(["a", "b"]) == %{"0" => "a", "1" => "b"}
    end

    test "normalizes a gappy map to dense indices" do
      assert Helpers.to_indexed_map(%{"0" => "a", "2" => "b"}) == %{"0" => "a", "1" => "b"}
    end

    test "drops non-digit keys such as LiveView _unused_ params" do
      assert Helpers.to_indexed_map(%{
               "0" => "a",
               "_unused_164" => "true",
               "1" => "b"
             }) == %{"0" => "a", "1" => "b"}
    end

    test "returns an empty map for nil" do
      assert Helpers.to_indexed_map(nil) == %{}
    end
  end

  describe "sanitize_form_params/1" do
    test "strips _unused_ keys and densifies indexed arrays" do
      params = %{
        "tags" => %{
          "0" => "hello",
          "2" => "world",
          "_unused_164" => "true",
          "_unused_459" => "true"
        },
        "_unused_other" => ""
      }

      assert Helpers.sanitize_form_params(params) == %{
               "tags" => %{"0" => "hello", "1" => "world"}
             }
    end

    test "leaves named nested maps alone" do
      params = %{"profile" => %{"name" => "Ada", "_unused_1" => ""}}

      assert Helpers.sanitize_form_params(params) == %{
               "profile" => %{"name" => "Ada"}
             }
    end
  end

  describe "normalize_argument_params/2" do
    test "converts array argument indexed maps to value lists" do
      arguments = [
        %Ash.Resource.Calculation.Argument{
          name: :tags,
          type: {:array, Ash.Type.String},
          allow_nil?: true,
          constraints: []
        }
      ]

      params = %{
        "tags" => %{"0" => "hello", "1" => "world", "_unused_9" => "true"}
      }

      assert Helpers.normalize_argument_params(params, arguments) == %{
               "tags" => ["hello", "world"]
             }
    end
  end

  describe "reorder_by_indices/2" do
    test "reorders values by a new index list" do
      map = %{"0" => "first", "1" => "second"}

      assert Helpers.reorder_by_indices(map, ["1", "0"]) == %{
               "0" => "second",
               "1" => "first"
             }
    end

    test "normalizes gappy maps before reordering" do
      map = %{"0" => "first", "2" => "second"}

      assert Helpers.reorder_by_indices(map, ["1", "0"]) == %{
               "0" => "second",
               "1" => "first"
             }
    end
  end
end
