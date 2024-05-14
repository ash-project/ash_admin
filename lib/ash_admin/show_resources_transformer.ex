defmodule AshAdmin.ShowResourcesTransformer do
  use Spark.Dsl.Transformer

  def transform(dsl) do
    module = Spark.Dsl.Transformer.get_persisted(dsl, :module)
    all_resources = Ash.Domain.Info.resources(dsl)

    resources =
      case AshAdmin.Domain.show_resources(dsl) do
        [:*] ->
          all_resources

        resources ->
          case Enum.find(resources, &(&1 not in all_resources)) do
            nil ->
              resources

            bad_resource ->
              raise Spark.Error.DslError,
                module: module,
                path: [:admin, :show_resources],
                message: "#{inspect(bad_resource)} is not a valid resource in #{inspect(module)}"
          end
      end

    {:ok, Spark.Dsl.Transformer.set_option(dsl, [:admin], :show_resources, resources)}
  end
end
