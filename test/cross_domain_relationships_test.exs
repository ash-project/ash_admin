defmodule AshAdmin.Test.CrossDomainRelationshipsTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  import Phoenix.LiveViewTest

  @endpoint AshAdmin.Test.Endpoint

  setup do
    # Configure the domains in the application environment
    Application.put_env(:ash_admin, :ash_domains, [
      AshAdmin.Test.DomainA,
      AshAdmin.Test.DomainB
    ])

    # Create an author in DomainB
    {:ok, author} =
      AshAdmin.Test.Author
      |> Ash.Changeset.for_create(:create, %{name: "Test Author"})
      |> Ash.create()

    # Create a post in DomainA that references the author
    {:ok, post} =
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{
        body: "Test Post",
        author_id: author.id
      })
      |> Ash.create()

    %{author: author, post: post}
  end

  describe "cross-domain relationships" do
    test "viewing a post shows its author from another domain", %{post: post} do
      {:ok, view, _html} =
        live(
          build_conn(),
          "/api/admin?domain=#{AshAdmin.Domain.name(AshAdmin.Test.DomainA)}&resource=Post&action_type=read&primary_key=#{post.id}"
        )

      # The view should show the post's details
      assert has_element?(view, "[data-test-id='post-body']", post.body)

      # The view should show the relationship to the author
      assert has_element?(view, "[data-test-id='relationship-author']")
    end

    test "viewing relationships across domains respects domain boundaries", %{post: post} do
      {:ok, view, _html} =
        live(
          build_conn(),
          "/api/admin?domain=#{AshAdmin.Domain.name(AshAdmin.Test.DomainA)}&resource=Post&action_type=read&primary_key=#{post.id}"
        )

      # Verify that cross-domain relationship actions are properly handled
      # This might mean certain actions are hidden or disabled
      refute has_element?(view, "[data-test-id='edit-author-button']")
    end
  end
end
