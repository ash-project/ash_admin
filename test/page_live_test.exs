# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.PageLiveTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  setup do
    %{conn: build_conn()}
  end

  test "it renders the schema by default", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/api/admin")

    assert html =~ "Attributes"
    assert html =~ "body"
    assert html =~ "String"

    {:ok, _view, html} = live(conn, "/api/admin/test")

    assert html =~ "Attributes"
    assert html =~ "body"
    assert html =~ "String"
  end

  test "embeds default csp nonces" do
    html =
      build_conn()
      |> get("/api/admin")
      |> html_response(200)

    assert html =~ "ash_admin-Ed55GFnX"
    assert html =~ ~s|<script nonce="ash_admin-Ed55GFnX"|
    assert html =~ ~s|<style nonce="ash_admin-Ed55GFnX"|
  end

  test "embeds user selected csp nonces" do
    html =
      build_conn()
      |> assign(:csp_nonce_value, "csp_nonce")
      |> get("/api/csp/admin")
      |> html_response(200)

    assert html =~ ~s|<script nonce="csp_nonce"|
    assert html =~ ~s|<style nonce="csp_nonce"|
    refute html =~ "ash_admin-Ed55GFnX"

    html =
      build_conn()
      |> assign(:script_csp_nonce, "script_nonce")
      |> assign(:style_csp_nonce, "style_nonce")
      |> get("/api/csp-full/admin")
      |> html_response(200)

    assert html =~ ~s|<script nonce="script_nonce"|
    assert html =~ ~s|<style nonce="style_nonce"|
    refute html =~ "ash_admin-Ed55GFnX"
  end

  test "allows uploading to an action with an upload argument", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Domain&resource=Post&action_type=create&action=create_with_photo"
      )

    file = File.read!("./logos/small-logo.png")

    photo =
      file_input(view, "#form", "form[photo]", [
        %{
          last_modified: 1_551_913_980,
          name: "small-logo.png",
          content: file,
          size: byte_size(file),
          type: "image/png"
        }
      ])

    assert view
           |> form("#form", user: %{})
           |> render_change(photo) =~ "data-progress=\"0\""

    assert render_upload(photo, "small-logo.png") =~ "data-progress=\"100\""
  end

  test "allows uploading to a related resource with an upload argument", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Domain&resource=Post&action_type=create&action=create_with_photo"
      )

    file = File.read!("./logos/small-logo.png")

    assert view
           |> element(~s{[phx-value-path="form[comments]"][phx-value-type="create"]})
           |> render_click()

    photo =
      file_input(view, "#form", "form[comments][0][photo]", [
        %{
          last_modified: 1_551_913_980,
          name: "small-logo.png",
          content: file,
          size: byte_size(file),
          type: "image/png"
        }
      ])

    assert view
           |> form("#form", user: %{})
           |> render_change(photo) =~ "data-progress=\"0\""

    assert render_upload(photo, "small-logo.png") =~ "data-progress=\"100\""
  end

  # simulates the Sortable.js hook pushing update_array_sorting after a drag reorder
  test "allows reordering primitive array items via drag-and-drop sorting", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/api/admin?domain=Test&resource=Post&action_type=create")

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> form("#form", %{"form" => %{"tags" => %{"0" => "first", "1" => "second"}}})
    |> render_change()

    # render_hook stands in for the client-side Sortable onEnd callback
    view
    |> element("#form_tags_sortable_list")
    |> render_hook("update_array_sorting", %{
      "path" => "form",
      "field" => "tags",
      "indices" => ["1", "0"]
    })

    assert has_element?(view, "input[name='form[tags][0]'][value='second']")
    assert has_element?(view, "input[name='form[tags][1]'][value='first']")
  end

  # DataTable query forms use the same Sortable UI; the event is handled on :query
  test "allows reordering array items on data table query forms", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Test&resource=Post&action_type=read&action=filter_by_tags"
      )

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> form("form[as=query]", %{"query" => %{"tags" => %{"0" => "first", "1" => "second"}}})
    |> render_change()

    view
    |> element("#query_tags_sortable_list")
    |> render_hook("update_array_sorting", %{
      "path" => "query",
      "field" => "tags",
      "indices" => ["1", "0"]
    })

    assert has_element?(view, "input[name='query[tags][0]'][value='second']")
    assert has_element?(view, "input[name='query[tags][1]'][value='first']")
  end

  # GenericAction parameter forms handle update_array_sorting on :form
  test "allows reordering array items on generic action forms", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Test&resource=Post&action_type=action&action=echo_tags"
      )

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> form("form[as=form]", %{"form" => %{"tags" => %{"0" => "first", "1" => "second"}}})
    |> render_change()

    view
    |> element("#form_tags_sortable_list")
    |> render_hook("update_array_sorting", %{
      "path" => "form",
      "field" => "tags",
      "indices" => ["1", "0"]
    })

    assert has_element?(view, "input[name='form[tags][0]'][value='second']")
    assert has_element?(view, "input[name='form[tags][1]'][value='first']")
  end

  # Show page calculations track args as maps, not AshPhoenix.Form structs
  test "allows reordering array items on show page calculation forms", %{conn: conn} do
    post =
      AshAdmin.Test.Post
      |> Ash.Changeset.for_create(:create, %{body: "hello"})
      |> Ash.create!()

    primary_key = AshAdmin.Helpers.encode_primary_key(post)

    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Test&resource=Post&action_type=read&primary_key=#{primary_key}"
      )

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> element("button[phx-click='append_value'][phx-value-field='tags']")
    |> render_click()

    view
    |> form("form[phx-change=validate-calculation]", %{
      "calculation" => "join_tags",
      "join_tags" => %{"tags" => %{"0" => "first", "1" => "second"}}
    })
    |> render_change()

    view
    |> element("#join_tags_tags_sortable_list")
    |> render_hook("update_array_sorting", %{
      "path" => "join_tags",
      "field" => "tags",
      "indices" => ["1", "0"]
    })

    assert has_element?(view, "input[name='join_tags[tags][0]'][value='second']")
    assert has_element?(view, "input[name='join_tags[tags][1]'][value='first']")
  end
end
