defmodule AshAdmin.Resource.Transformers.ValidateTableColumns do
  @moduledoc "Validates that table columns are all either attributes, or `:one` cardinality relationships."
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  def transform(dsl_state) do
    relationships =
      dsl_state
      |> Transformer.get_entities([:relationships])
      |> Enum.filter(&(&1.cardinality == :one))
      |> Enum.map(& &1.name)

    attributes =
      dsl_state
      |> Transformer.get_entities([:attributes])
      |> Enum.map(& &1.name)

    valid_fields = Enum.concat(relationships, attributes)

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
