# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.ShowResourcesTransformer do
  @moduledoc false
  use Spark.Dsl.Transformer

  @dialyzer {:nowarn_function, {:transform, 1}}

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
