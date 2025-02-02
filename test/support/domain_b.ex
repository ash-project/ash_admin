defmodule AshAdmin.Test.DomainB do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
    group :group_b
  end

end
