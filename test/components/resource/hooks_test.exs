# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.HooksTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint AshAdmin.Test.Endpoint

  # AshAdmin serves its own prebuilt app.js, so a hook that a component renders
  # (including Cinder's colocated ones) does nothing unless that bundle
  # registers it. LiveView only logs an "unknown hook" error in the browser.
  test "every hook the table and its filters render is registered in the bundle" do
    {:ok, view, _html} =
      live(build_conn(), "/api/admin?domain=Domain&resource=Blog&action_type=read")

    render_async(view)

    view
    |> element("button[phx-click=toggle_filters]")
    |> render_click()

    hooks =
      view
      |> render_async()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("[phx-hook]")
      |> LazyHTML.attribute("phx-hook")
      |> Enum.uniq()

    assert "Cinder.FilterManager.PartialInputs" in hooks

    app_js = AshAdmin.Layouts.render("app.js", %{})

    for hook <- hooks do
      name = Regex.escape(hook)

      assert app_js =~ ~r/(\["#{name}"\]|\.#{name})\s*=/,
             "#{hook} is rendered but not registered in priv/static/assets/app.js"
    end
  end
end
