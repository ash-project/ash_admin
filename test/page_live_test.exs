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
    assert html =~ ~s|<link nonce="csp_nonce"|
    refute html =~ "ash_admin-Ed55GFnX"

    html =
      build_conn()
      |> assign(:script_csp_nonce, "script_nonce")
      |> assign(:style_csp_nonce, "style_nonce")
      |> get("/api/csp-full/admin")
      |> html_response(200)

    assert html =~ ~s|<script nonce="script_nonce"|
    assert html =~ ~s|<style nonce="style_nonce"|
    assert html =~ ~s|<link nonce="style_nonce"|
    refute html =~ "ash_admin-Ed55GFnX"
  end
end
