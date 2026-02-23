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
end
