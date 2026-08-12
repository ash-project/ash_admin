# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.HelpersTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Helpers

  defmodule CompositeKey do
    @moduledoc false
    use Ash.Resource, domain: nil, validate_domain_inclusion?: false

    attributes do
      attribute :org_id, :integer, primary_key?: true, allow_nil?: false, public?: true
      attribute :seq, :integer, primary_key?: true, allow_nil?: false, public?: true
    end
  end

  describe "decode_primary_key/2" do
    test "round-trips a composite primary key" do
      record = struct(CompositeKey, org_id: 1, seq: 2)
      encoded = Helpers.encode_primary_key(record)

      assert {:ok, decoded} = Helpers.decode_primary_key(CompositeKey, encoded)
      assert Enum.sort(decoded) == [org_id: 1, seq: 2]
    end

    test "rejects a forged param carrying an Ash expression struct" do
      forged =
        %{org_id: %Ash.Query.Call{name: :fragment, args: ["select pg_sleep(10)"]}, seq: 1}
        |> :erlang.term_to_binary()
        |> Base.encode64()

      assert :error = Helpers.decode_primary_key(CompositeKey, forged)
    end

    test "rejects an oversized param" do
      oversized =
        %{org_id: :binary.copy("a", 20_000), seq: 1}
        |> :erlang.term_to_binary()
        |> Base.encode64()

      assert :error = Helpers.decode_primary_key(CompositeKey, oversized)
    end

    test "rejects a compressed payload" do
      compressed =
        %{org_id: :binary.copy("a", 5_000), seq: 1}
        |> :erlang.term_to_binary(compressed: 9)
        |> Base.encode64()

      assert :error = Helpers.decode_primary_key(CompositeKey, compressed)
    end

    test "rejects invalid base64" do
      assert :error = Helpers.decode_primary_key(CompositeKey, "not base64!!!")
    end
  end

  # unit tests for array reordering helpers used by Sortable.js drag-and-drop
  describe "to_indexed_map/1" do
    test "converts a list to a string-indexed map" do
      assert Helpers.to_indexed_map(["a", "b"]) == %{"0" => "a", "1" => "b"}
    end

    test "normalizes a gappy map to dense indices" do
      assert Helpers.to_indexed_map(%{"0" => "a", "2" => "b"}) == %{"0" => "a", "1" => "b"}
    end

    test "returns an empty map for nil" do
      assert Helpers.to_indexed_map(nil) == %{}
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
