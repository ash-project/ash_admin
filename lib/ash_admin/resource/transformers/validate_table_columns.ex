# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Transformers.ValidateTableColumns do
  @moduledoc "Validates that table columns are all either attributes, or `:one` cardinality relationships."
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  def transform(dsl_state) do
    relationships =
      dsl_state
      |> Ash.Resource.Info.relationships()
      |> Enum.filter(&(&1.cardinality == :one))

    valid_fields =
      dsl_state
      |> Ash.Resource.Info.attributes()
      |> Enum.concat(Ash.Resource.Info.calculations(dsl_state))
      |> Enum.concat(Ash.Resource.Info.aggregates(dsl_state))
      |> Enum.concat(relationships)
      |> Enum.map(& &1.name)

    bad_columns =
      dsl_state
      |> Transformer.get_option([:admin], :table_columns)
      |> List.wrap()
      |> Enum.reject(&(&1 in valid_fields))

    if Enum.empty?(bad_columns) do
      {:ok, dsl_state}
    else
      raise """
      Invalid table columns: #{inspect(bad_columns)}
      Only attributes, has_one, or belongs_to relationships are allowed.
      Valid columns: #{inspect(valid_fields)}
      """
    end
  end

  def after?(Ash.Resource.Transformers.BelongsToAttribute), do: true
  def after?(_), do: false
end
