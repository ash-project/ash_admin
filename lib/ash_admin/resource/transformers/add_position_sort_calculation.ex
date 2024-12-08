defmodule AshAdmin.Resource.Transformers.AddPositionSortCalculation do
  @moduledoc """
  Adds a `ash_admin_position_sort` calculation to resources that have defined admin.label_field.
  This calculation is used when loading typeahead search suggestions in a related resource field.
  """

  use Spark.Dsl.Transformer
  use Ash.Resource.Calculation

  alias Spark.Dsl.Transformer
  alias AshAdmin.Resource.Transformers.AddPositionSortCalculation, as: AddPositionSortCalculation
  @impl true
  def transform(dsl) do
    case Transformer.get_persisted(dsl, :data_layer) do
      nil ->
        {:ok, dsl}

      data_layer ->
        case Transformer.get_option(dsl, [:admin], :label_field) do
          nil ->
            {:ok, dsl}

          label_field ->
            opts = [
              name: :ash_admin_position_sort,
              type: :integer,
              calculation: calculation(label_field, data_layer),
              arguments: [
                %{name: :search_term, type: :string, constraints: [], default: ""}
              ],
              sortable?: true,
              load: [field: label_field]
            ]

            case Transformer.build_entity(
                   Ash.Resource.Dsl,
                   [:calculations],
                   :calculate,
                   opts
                 ) do
              {:ok, calculation} ->
                {:ok, Transformer.add_entity(dsl, [:calculations], calculation)}

              error ->
                error
            end
        end
    end
  end

  defp calculation(label_field, AshPostgres.DataLayer) do
    expr(
      fragment(
        "CASE WHEN POSITION(UPPER(?) IN UPPER(?)) = 0 THEN NULL ELSE POSITION(UPPER(?) IN UPPER(?)) END",
        :search_term,
        ^ref(label_field),
        :search_term,
        ^ref(label_field)
      )
    )
  end

  defp calculation(label_field, data_layer)
       when data_layer in [Ash.DataLayer.Ets, Ash.DataLayer.Simple] do
    expr(
      fragment(
        &AddPositionSortCalculation.find_substring_position/2,
        ^ref(label_field),
        ^arg(:search_term)
      )
    )
  end

  defp calculation(_label_field, data_layer) do
    IO.inspect("Data layer #{inspect(data_layer)} does not support typeahead suggestion sorting.")

    expr(0)
  end

  def find_substring_position(substring, string) do
    case String.split(string, substring, parts: 2) do
      [before, _after] -> String.length(before)
      _ -> nil
    end
  end
end
