defmodule AshAdmin.Test.Components.TopNav.Helpers.DropdownHelperTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Components.TopNav.DropdownHelper

  describe "dropdown_groups/3" do
    test "groups resources" do
      prefix = "/admin"
      current_resource = AshAdmin.Test.Post
      domain = AshAdmin.Test.Domain

      post_link = %{
        active: true,
        group: nil,
        text: "Post",
        to: "/admin?domain=Test&resource=Post"
      }

      comment_link = %{
        active: false,
        group: nil,
        text: "Comment",
        to: "/admin?domain=Test&resource=Comment"
      }

      assert_unordered(
        [[post_link, comment_link]],
        DropdownHelper.dropdown_groups(prefix, current_resource, domain)
      )
    end
  end

  describe "dropdown_group_labels/1" do
    test "returns groups" do
      domain = AshAdmin.Test.Domain

      assert [] = DropdownHelper.dropdown_group_labels(domain)
    end
  end

  defp assert_unordered(enum, other_enum) do
    assert MapSet.new(enum) == MapSet.new(other_enum)
  end
end
