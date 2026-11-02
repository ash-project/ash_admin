# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.ShowRelationshipFieldsTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  alias AshAdmin.Test.{
    RelationshipFieldsArticle,
    RelationshipFieldsAuthor,
    RelationshipFieldsBook
  }

  setup do
    favorite = Ash.create!(RelationshipFieldsBook, %{title: "Favorite", isbn: "978-1"})

    author =
      Ash.create!(RelationshipFieldsAuthor, %{name: "Ada", favorite_book_id: favorite.id})

    Ash.create!(RelationshipFieldsBook, %{title: "Notes", isbn: "978-0", author_id: author.id})

    Ash.create!(RelationshipFieldsArticle, %{
      headline: "Analytical engine",
      summary: "A summary",
      author_id: author.id
    })

    {:ok, view, _html} = live(build_conn(), show_path(author))

    %{view: view}
  end

  defp show_path(author) do
    AshAdmin.Helpers.admin_path("/api/admin",
      domain: AshAdmin.Domain.name(AshAdmin.Test.RelationshipFieldsDomain),
      resource: "RelationshipFieldsAuthor",
      primary_key: author.id,
      action_type: "read"
    )
  end

  defp load(view, relationship) do
    tab = "#relationship-tab-#{relationship}"
    if has_element?(view, tab), do: view |> element(tab) |> render_click()

    view
    |> element(~s|button[phx-click=load][phx-value-relationship="#{relationship}"]|)
    |> render_click()
  end

  test "a has_many relationship only shows the configured columns", %{view: view} do
    html = load(view, :books)

    assert html =~ "Title"
    assert html =~ "Notes"
    refute html =~ "Isbn"
    refute html =~ "978-0"
  end

  test "a belongs_to relationship only shows the configured fields", %{view: view} do
    html = render(view)

    assert html =~ "Favorite"
    refute html =~ "Isbn"
    refute html =~ "978-1"
  end

  test "a relationship without configuration shows every attribute", %{view: view} do
    html = load(view, :articles)

    assert html =~ "Headline"
    assert html =~ "Summary"
    assert html =~ "A summary"
  end

  test "the verifier rejects an unknown relationship" do
    dsl =
      put_in(
        RelationshipFieldsAuthor.spark_dsl_config(),
        [[:admin], :opts, :show_relationship_fields],
        nope: [:title]
      )

    assert {:error, %Spark.Error.DslError{message: message}} =
             AshAdmin.Resource.Verifiers.VerifyShowRelationshipFields.verify(dsl)

    assert message =~ "is not a relationship"
  end

  test "the verifier rejects a field that is not an attribute of the destination" do
    dsl =
      put_in(
        RelationshipFieldsAuthor.spark_dsl_config(),
        [[:admin], :opts, :show_relationship_fields],
        books: [:nope]
      )

    assert {:error, %Spark.Error.DslError{message: message}} =
             AshAdmin.Resource.Verifiers.VerifyShowRelationshipFields.verify(dsl)

    assert message =~ "Invalid fields"
  end
end
