defmodule AshAdmin.Components.Resource.Helpers.FormatHelper do
  @moduledoc false

  def format_attribute(formats, record, attribute) do
    {mod, func, args} =
      Keyword.get(formats || [], attribute.name, {Phoenix.HTML.Safe, :to_iodata, []})

    record
    |> Map.get(attribute.name)
    |> then(&apply(mod, func, [&1] ++ args))
  end
end
