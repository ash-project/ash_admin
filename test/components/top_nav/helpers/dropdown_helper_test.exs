defmodule AshAdmin.Test.Components.TopNav.Helpers.DropdownHelperTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Components.TopNav.DropdownHelper

  describe "dropdown_groups/3" do
    test "groups resources" do
      prefix = "/admin"
      current_resource = AshAdmin.Test.Post
      domain = AshAdmin.Test.DomainA

      blog_link = %{
        active: false,
        group: :group_b,
        text: "Blog",
        to: "/admin?domain=DomainA&resource=Blog"
      }

      post_link = %{
        active: true,
        group: :group_a,
        text: "Post",
        to: "/admin?domain=DomainA&resource=Post"
      }

      comment_link = %{
        active: false,
        group: nil,
        text: "Comment",
        to: "/admin?domain=DomainA&resource=Comment"
      }

      assert_unordered(
        [[blog_link], [comment_link], [post_link]],
        DropdownHelper.dropdown_groups(prefix, current_resource, domain)
      )
    end

    test "groups resources by given order from the domain" do
      prefix = "/admin"
      current_resource = AshAdmin.Test.Post
      domain = AshAdmin.Test.DomainA

      assert [
               [%{group: :group_b, text: "Blog"} = _blog_link],
               [%{group: :group_a, text: "Post"} = _post_link],
               [%{group: nil, text: "Comment"} = _comment_link]
             ] = DropdownHelper.dropdown_groups(prefix, current_resource, domain)
    end
  end

  describe "dropdown_group_labels/3" do
    test "returns groups" do
      domain = AshAdmin.Test.DomainA

      assert [group_b: "Group B", group_a: "Group A", group_c: "Group C"] =
               DropdownHelper.dropdown_group_labels(domain)
    end
  end

  defp assert_unordered(enum, other_enum) do
    assert MapSet.new(enum) == MapSet.new(other_enum)
  end
end
