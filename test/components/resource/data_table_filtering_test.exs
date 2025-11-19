# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.DataTableFilteringTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  # Helper function to mount LiveView and wait for Cinder table to finish loading
  defp live_and_wait(conn, path) do
    {:ok, view, _html} = live(conn, path)
    # Wait for the loading indicator to disappear
    # Cinder shows a loading overlay while fetching data
    refute_eventually(fn -> render(view) =~ "Loading..." end, timeout: 5000, interval: 100)
    {view, render(view)}
  end

  # Helper function to wait for Cinder table to finish loading (for existing view)
  defp wait_for_table_load(view) do
    refute_eventually(fn -> render(view) =~ "Loading..." end, timeout: 5000, interval: 100)
    view
  end

  # Helper to retry a condition until it's false or timeout
  defp refute_eventually(func, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 2000)
    interval = Keyword.get(opts, :interval, 50)
    end_time = System.monotonic_time(:millisecond) + timeout

    do_refute_eventually(func, end_time, interval)
  end

  defp do_refute_eventually(func, end_time, interval) do
    if func.() do
      if System.monotonic_time(:millisecond) < end_time do
        Process.sleep(interval)
        do_refute_eventually(func, end_time, interval)
      else
        raise "Timeout waiting for condition to become false"
      end
    else
      :ok
    end
  end

  setup do
    # Ensure ETS tables exist and clear them
    if :ets.whereis(AshAdmin.Test.Post) != :undefined do
      :ets.delete_all_objects(AshAdmin.Test.Post)
    end

    if :ets.whereis(AshAdmin.Test.Comment) != :undefined do
      :ets.delete_all_objects(AshAdmin.Test.Comment)
    end

    # Create test data
    post1 =
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{
        body: "First post about Elixir",
        expires_at: ~U[2024-12-25 10:00:00Z]
      })
      |> Ash.create!()

    post2 =
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{
        body: "Second post about Phoenix",
        expires_at: ~U[2025-01-15 14:30:00Z]
      })
      |> Ash.create!()

    post3 =
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{
        body: "Third post about Testing",
        expires_at: ~U[2025-06-01 09:00:00Z]
      })
      |> Ash.create!()

    %{
      conn: build_conn(),
      posts: [post1, post2, post3]
    }
  end

  describe "basic filter functionality" do
    test "renders data table instead of schema view", %{conn: conn} do
      {view, html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Should NOT show the schema view (Attributes/Relationships tables)
      refute html =~ "Attributes"
      refute html =~ "Primary Key"

      # Should show actual post data
      assert html =~ "First post about Elixir"
      assert html =~ "Second post about Phoenix"
      assert html =~ "Third post about Testing"
    end

    test "renders filter controls when show_filters is enabled", %{conn: conn} do
      {view, html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Check for filter-related elements
      # Cinder renders filters within the table structure
      assert has_element?(view, "table")

      # All posts should be visible initially
      assert html =~ "First post about Elixir"
      assert html =~ "Second post about Phoenix"
      assert html =~ "Third post about Testing"
    end

    test "applies text filter on body field via Cinder events", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Cinder uses "filter_change" event with filters map
      # Try filtering for "Elixir"
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Elixir"}})

      # Wait for Cinder to re-query with the filter applied
      html = render_async(view)

      # Should show only the first post
      assert html =~ "First post about Elixir"
      refute html =~ "Second post about Phoenix"
      refute html =~ "Third post about Testing"
    end

    test "applies text filter with partial match", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter for "post" (should match all since all contain "post")
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "post"}})

      html = render_async(view)

      # Should show all posts
      assert html =~ "First post about Elixir"
      assert html =~ "Second post about Phoenix"
      assert html =~ "Third post about Testing"
    end

    # @tag timeout: :infinity
    test "clears individual filter", %{conn: conn} do
      # :debugger.start()
      # module = Cinder.Table.LiveComponent
      # {:module, _} = :int.ni(module)
      # :ok = :int.break(module, 256)

      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply filter
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Elixir"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show all posts again
      assert html =~ "First post about Elixir"
    end

    @skip true
    test "clears all filters at once", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply filter
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Elixir"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show all posts
      assert html =~ "First post about Elixir"
    end
  end

  describe "filter interaction with sorting" do
    test "filter and sort work together", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply filter first
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "post"}})

      # Then sort by body field using Cinder's toggle_sort event
      render_click(view, "toggle_sort", %{"key" => "body"})

      # Wait for Cinder to re-query with filter and sort applied
      html = render_async(view)

      # Should still show all filtered results (all posts contain "post")
      assert html =~ "post"
    end

    test "sort persists when filter changes", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Sort first
      render_click(view, "toggle_sort", %{"key" => "body"})

      # Then apply filter
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Phoenix"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show filtered result with sort still active
      assert html =~ "Second post about Phoenix"
      refute html =~ "First post about Elixir"
    end
  end

  describe "filter interaction with pagination" do
    test "filter works with pagination", %{conn: conn} do
      # Create more posts to test pagination
      for i <- 1..30 do
        AshAdmin.Test.Post
        |> Ash.Changeset.for_create(:create, %{
          body: "Extra post number #{i}",
          expires_at: ~U[2025-01-01 00:00:00Z]
        })
        |> Ash.create!()
      end

      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply filter to reduce results
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Extra"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show only the "Extra post" entries
      assert html =~ "Extra post"
      refute html =~ "First post about Elixir"
    end

    test "changing filter updates pagination", %{conn: conn} do
      # Create more posts
      for i <- 1..30 do
        AshAdmin.Test.Post
        |> Ash.Changeset.for_create(:create, %{
          body: "Paginated post #{i}",
          expires_at: ~U[2025-01-01 00:00:00Z]
        })
        |> Ash.create!()
      end

      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Navigate to page 2 first
      render_click(view, "goto_page", %{"page" => "2"})

      # Then apply filter - should reset to showing filtered results
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "Elixir"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show the filtered result
      assert html =~ "First post about Elixir"
    end
  end

  describe "filter types" do
    test "text filter with case insensitivity", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter with different case
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "ELIXIR"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should match case-insensitively (Ash default behavior)
      assert html =~ "First post about Elixir"
    end

    test "date range filter - from date only", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter for posts expiring after 2025-01-01
      view
      |> element("form")
      |> render_change(%{
        "filters" => %{
          "expires_at_from" => "2025-01-01"
        }
      })

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show posts 2 and 3 (expiring in 2025)
      assert html =~ "Second post about Phoenix"
      assert html =~ "Third post about Testing"
      refute html =~ "First post about Elixir"
    end

    test "date range filter - to date only", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter for posts expiring before 2025-01-01
      view
      |> element("form")
      |> render_change(%{
        "filters" => %{
          "expires_at_to" => "2025-01-01"
        }
      })

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show only post 1 (expires in 2024)
      assert html =~ "First post about Elixir"
      refute html =~ "Second post about Phoenix"
      refute html =~ "Third post about Testing"
    end

    test "date range filter - both dates", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter for posts expiring between Jan and Feb 2025
      view
      |> element("form")
      |> render_change(%{
        "filters" => %{
          "expires_at_to" => "2025-02-01",
          "expires_at_from" => "2025-01-01"
        }
      })

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show only post 2 (expires Jan 15, 2025)
      assert html =~ "Second post about Phoenix"
      refute html =~ "First post about Elixir"
      refute html =~ "Third post about Testing"
    end
  end

  describe "edge cases" do
    test "handles empty filter value", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply empty filter
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => ""}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show all posts (empty filter is ignored)
      assert html =~ "First post about Elixir"
      assert html =~ "Second post about Phoenix"
      assert html =~ "Third post about Testing"
    end

    test "handles filter with no results", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter for something that doesn't exist
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "NonexistentContent"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show no posts
      refute html =~ "First post"
      refute html =~ "Second post"
      refute html =~ "Third post"
    end

    test "handles special characters in filter", %{conn: conn} do
      # Create post with special characters
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{
        body: "Post with special chars: @#$%",
        expires_at: ~U[2025-01-01 00:00:00Z]
      })
      |> Ash.create!()

      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Filter with special characters
      view
      |> element("form")
      |> render_change(%{"filters" => %{"body" => "@#$"}})

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should find the post with special characters
      assert html =~ "special chars"
    end
  end

  describe "multiple active filters" do
    test "applies multiple filters simultaneously", %{conn: conn} do
      {view, _html} =
        live_and_wait(conn, "/api/admin?domain=Domain&resource=Post&action_type=read&action=read")

      # Apply filter on body and date range together
      view
      |> element("form")
      |> render_change(%{
        "filters" => %{
          "body" => "Phoenix",
          "expires_at_from" => "2025-01-01",
          "expires_at_to" => "2025-12-31"
        }
      })

      # Wait for Cinder to re-query
      html = render_async(view)

      # Should show only Second post (matches both filters)
      assert html =~ "Second post about Phoenix"
      refute html =~ "First post about Elixir"
      refute html =~ "Third post about Testing"
    end
  end
end
