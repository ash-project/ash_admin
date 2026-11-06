# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.SensitiveFieldsTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias AshAdmin.Test.Credential

  @endpoint AshAdmin.Test.Endpoint
  @path "/api/admin?domain=Sensitive&resource=Credential"

  setup do
    id = System.unique_integer([:positive])

    credential =
      Ash.create!(Credential, %{
        name: "Payments #{id}",
        token: "secret-token-#{id}",
        label: "shown-label-#{id}"
      })

    %{conn: build_conn(), credential: credential}
  end

  test "by default the eye icon reveals a sensitive value", %{conn: conn, credential: credential} do
    {:ok, view, html} = live(conn, record_path(credential, "read"))
    refute html =~ credential.token

    html =
      view
      |> element("[phx-click=toggle_sensitive_attribute]")
      |> render_click()

    assert html =~ credential.token
  end

  describe "with reveal_sensitive_fields? set to false" do
    setup do
      Application.put_env(:ash_admin, :reveal_sensitive_fields?, false)
      on_exit(fn -> Application.delete_env(:ash_admin, :reveal_sensitive_fields?) end)
    end

    test "the record page has no reveal, and refuses one sent without the icon", %{
      conn: conn,
      credential: credential
    } do
      {:ok, view, html} = live(conn, record_path(credential, "read"))

      assert html =~ "--redacted--"
      refute html =~ credential.token
      refute has_element?(view, "[phx-click=toggle_sensitive_attribute]")
      # listed in `show_sensitive_fields`
      assert html =~ credential.label

      html =
        view
        |> with_target("div[data-phx-component]:has(> span.italic)")
        |> render_click("toggle_sensitive_attribute", %{})

      refute html =~ credential.token
    end

    test "the table neither filters, sorts nor searches on a sensitive column", %{
      conn: conn,
      credential: credential
    } do
      {:ok, view, _html} = live(conn, @path <> "&action_type=read")

      view
      |> element("button[phx-click=toggle_filters]")
      |> render_click()

      html = render_async(view)
      assert html =~ credential.name
      refute html =~ credential.token
      assert has_element?(view, "[phx-click=toggle_sort][phx-value-key=name]")
      refute has_element?(view, "[phx-click=toggle_sort][phx-value-key=token]")
      assert html =~ ~s(name="filters[name]")
      refute html =~ ~s(name="filters[token]")

      # Sent anyway, a filter or a search on the column tells nothing about its values
      view
      |> element("form[phx-change=filter_change]")
      |> render_change(%{"filters" => %{"token" => "no such token"}})

      assert render_async(view) =~ credential.name

      view
      |> element("form[phx-change=filter_change]")
      |> render_change(%{"search" => credential.token})

      refute render_async(view) =~ credential.name
    end

    test "update forms leave sensitive attributes out, so saving keeps them", %{
      conn: conn,
      credential: credential
    } do
      {:ok, view, html} = live(conn, record_path(credential, "update"))

      refute html =~ credential.token
      refute has_element?(view, "input[name='form[token]']")
      assert has_element?(view, "input[name='form[label]']")

      view
      |> form("#form", %{"form" => %{"name" => "Renamed"}})
      |> render_submit()

      updated = Ash.get!(Credential, credential.id)
      assert updated.name == "Renamed"
      assert updated.token == credential.token
    end

    test "create forms still take sensitive attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, @path <> "&action_type=create")

      assert has_element?(view, "input[type=password][name='form[token]']")
    end
  end

  defp record_path(record, action_type) do
    @path <> "&action_type=#{action_type}&primary_key=#{record.id}"
  end
end
