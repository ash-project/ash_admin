defmodule AshAdmin.Resource.Transformers.AddPositionSortCalculation do
  @moduledoc """
  Adds a `ash_admin_position_sort` calculation to resources with admin.label_field defined.
  """

  use Spark.Dsl.Transformer
  use Ash.Resource.Calculation

  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    case Transformer.get_option(dsl, [:admin], :label_field) do
      nil ->
        {:ok, dsl}

      label_field ->
        with opts <- [
               name: :ash_admin_position_sort,
               type: :integer,
               calculation: expr(position(^arg(:search_term), ^ref(label_field))),
               arguments: [
                 %{name: :search_term, type: :string, constraints: [], default: ""}
               ],
               sortable?: true,
               load: [field: label_field]
             ],
             {:ok, calculation} <-
               Transformer.build_entity(Ash.Resource.Dsl, [:calculations], :calculate, opts) do
          {:ok, Transformer.add_entity(dsl, [:calculations], calculation)}
        end
    end
  end
end
