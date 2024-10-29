defmodule AshAdmin.Expressions.Position do
  @moduledoc """
  Provides an expression for finding the position of a substring within a string.

  This expression can be used in Ash queries to perform case-insensitive substring matching and return the position of the substring within the string, or `nil` if the substring is not found.

  The expression supports the following data layers:
  - `AshPostgres.DataLayer`
  - `Ash.DataLayer.Ets` and `Ash.DataLayer.Simple`

  """
  use Ash.CustomExpression,
    name: :position,
    arguments: [
      [:string, :string]
    ]

  alias AshAdmin.Expressions.Position, as: Position

  def expression(AshPostgres.DataLayer, [substring, string]) do
    {:ok,
     expr(
       fragment(
         "CASE WHEN POSITION(UPPER(?) IN UPPER(?)) = 0 THEN NULL ELSE POSITION(UPPER(?) IN UPPER(?)) END",
         ^substring,
         ^string,
         ^substring,
         ^string
       )
     )}
  end

  def expression(data_layer, [substring, string])
      when data_layer in [
             Ash.DataLayer.Ets,
             Ash.DataLayer.Simple
           ] do
    {:ok, expr(fragment(&Position.find_substring_position/2, ^substring, ^string))}
  end

  def expression(_data_layer, _args), do: :unknown

  def find_substring_position(substring, string) do
    case String.split(string, substring, parts: 2) do
      [before, _after] -> String.length(before)
      _ -> nil
    end
  end
end
