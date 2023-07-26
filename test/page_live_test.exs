defmodule AshAdmin.Test.PageLiveTest do
  use ExUnit.Case, async: false

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
end
