defmodule AshAdmin.Resource.Transformers.ValidateTableColumns do
  @moduledoc "Validates that table columns are all either attributes, or `:one` cardinality relationships."
  use Ash.Dsl.Transformer

  def transform(resource, dsl_state) do
    relationships =
      resource
      |> Ash.Resource.Info.relationships()
      |> Enum.filter(&(&1.cardinality == :one))
      |> Enum.map(& &1.name)

    attributes =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.map(& &1.name)

    valid_fields = Enum.concat(relationships, attributes)

    bad_columns =
      resource
      |> AshAdmin.Resource.table_columns()
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
