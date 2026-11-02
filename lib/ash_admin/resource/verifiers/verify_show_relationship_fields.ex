# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Resource.Verifiers.VerifyShowRelationshipFields do
  @moduledoc """
  Ensures that every key of `show_relationship_fields` is a relationship of the
  resource, and that every field is an attribute of the destination resource.
  """

  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> Verifier.get_option([:admin], :show_relationship_fields, [])
    |> Enum.reduce_while(:ok, fn {relationship_name, fields}, :ok ->
      case check(dsl_state, relationship_name, fields) do
        :ok -> {:cont, :ok}
        {:error, message} -> {:halt, {:error, error(dsl_state, message)}}
      end
    end)
  end

  defp check(dsl_state, relationship_name, fields) do
    case Ash.Resource.Info.relationship(dsl_state, relationship_name) do
      nil ->
        {:error, "`#{inspect(relationship_name)}` is not a relationship of this resource."}

      %{destination: destination} when is_list(fields) ->
        valid = destination |> Ash.Resource.Info.attributes() |> Enum.map(& &1.name)

        case Enum.reject(fields, &(&1 in valid)) do
          [] ->
            :ok

          invalid ->
            {:error,
             """
             Invalid fields for relationship `#{inspect(relationship_name)}`: #{inspect(invalid)}
             Only attributes of #{inspect(destination)} are allowed.
             Valid fields: #{inspect(valid)}
             """}
        end

      _ ->
        {:error,
         "Fields for relationship `#{inspect(relationship_name)}` must be a list of atoms."}
    end
  end

  defp error(dsl_state, message) do
    Spark.Error.DslError.exception(
      message: message,
      path: [:admin, :show_relationship_fields],
      module: Verifier.get_persisted(dsl_state, :module)
    )
  end
end
