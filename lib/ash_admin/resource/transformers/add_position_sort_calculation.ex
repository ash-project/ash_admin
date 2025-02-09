defmodule AshAdmin.Resource.Transformers.AddPositionSortCalculation do
  @moduledoc """
  Adds a `ash_admin_position_sort` calculation to resources that have defined admin.label_field.
  This calculation is used to sort typeahead search suggestions in a related resource field.
  """

  use Spark.Dsl.Transformer
  use Ash.Resource.Calculation

  require Logger

  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    case Transformer.get_option(dsl, [:admin], :label_field) do
      nil ->
        {:ok, dsl}

      label_field ->
        calculation_expr =
          if function_exported?(Ash.Query.Function, :string_position, 2) do
            expr(string_position(^ref(label_field), ^arg(:search_term)))
          else
            expr(string_length(^ref(label_field)))
          end

        opts = [
          name: :ash_admin_position_sort,
          type: :integer,
          calculation: calculation_expr,
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
