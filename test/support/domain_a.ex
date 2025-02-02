defmodule AshAdmin.Test.DomainA do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
    resource_group_labels group_b: "Group B", group_a: "Group A", group_c: "Group C"
  end

  resources do
    resource(AshAdmin.Test.Blog)
    resource(AshAdmin.Test.Post)
    resource(AshAdmin.Test.Comment)
  end
end
