defmodule AshAdmin.Test.Domain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(AshAdmin.Test.Post)
    resource(AshAdmin.Test.Comment)
  end
end
