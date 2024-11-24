defmodule AshAdmin.Test.Post.AdminFieldFormats do
  @moduledoc false

  def format_field(datetime, field) when field in [:expires_at],
    do: Calendar.strftime(datetime, "%c.%f")
end
