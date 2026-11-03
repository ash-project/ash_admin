# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.DataTableSearchTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint AshAdmin.Test.Endpoint

  setup do
    Ash.create!(AshAdmin.Test.Blog, %{body: "Apple pie"})
    Ash.create!(AshAdmin.Test.Blog, %{body: "Banana bread"})

    %{conn: build_conn()}
  end

  test "the search box filters rows on the searchable columns", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/api/admin?domain=Domain&resource=Blog&action_type=read")

    html = render_async(view)
    assert html =~ "Apple pie"
    assert html =~ "Banana bread"

    # The search box is hidden with the filters until the Filters button is clicked
    refute html =~ ~s(name="search")

    view
    |> element("button[phx-click=toggle_filters]")
    |> render_click()

    assert render_async(view) =~ ~s(name="search")

    view
    |> element("form[phx-change=filter_change]")
    |> render_change(%{"search" => "banana"})

    html = render_async(view)
    refute html =~ "Apple pie"
    assert html =~ "Banana bread"
  end

  test "a table without searchable columns has no search box", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/api/admin?domain=ManyToMany&resource=Profile&action_type=read")

    render_async(view)

    view
    |> element("button[phx-click=toggle_filters]")
    |> render_click()

    refute render_async(view) =~ ~s(name="search")
  end
end
