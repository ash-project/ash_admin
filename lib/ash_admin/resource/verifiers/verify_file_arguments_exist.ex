# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Verifiers.VerifyFileArgumentsExist do
  @moduledoc """
  Ensures that an argument with file options exists in an action of the
  resource.
  """

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshAdmin.Resource.fields()
    |> Enum.filter(&file_options_set?/1)
    |> Enum.reduce_while(:ok, fn field, _acc ->
      if argument_exists?(dsl_state, field.name) do
        {:cont, :ok}
      else
        {:halt,
         {:error,
          Spark.Error.DslError.exception(
            message: """
            `#{field.name}` has `max_file_size` or `accepted_extensions` set but
            `#{module_name(dsl_state)}` has no action with an argument named `#{field.name}` with type `Ash.File.Type`.",
            """,
            path: [:admin, :form, :field, field.name],
            module: Verifier.get_persisted(dsl_state, :module)
          )}}
      end
    end)
  end

  defp module_name(dsl_state) do
    String.trim_leading(to_string(Verifier.get_persisted(dsl_state, :module)), "Elixir.")
  end

  defp argument_exists?(dsl_state, name) do
    dsl_state
    |> Ash.Resource.Info.actions()
    |> Enum.flat_map(fn action -> action.arguments end)
    |> Enum.any?(fn argument ->
      argument.name == name
    end)
  end

  defp file_options_set?(field) do
    not is_nil(field.max_file_size) or
      not is_nil(field.accepted_extensions)
  end
end
