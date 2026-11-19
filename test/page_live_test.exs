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

  test "it shows the configured title", %{conn: conn} do
    previous = Application.get_env(:ash_admin, :title)

    on_exit(fn ->
      if previous do
        Application.put_env(:ash_admin, :title, previous)
      else
        Application.delete_env(:ash_admin, :title)
      end
    end)

    {:ok, _view, html} = live(conn, "/api/admin")
    assert html =~ "Ash Admin"

    Application.put_env(:ash_admin, :title, "Acme Back Office")

    html = conn |> get("/api/admin") |> html_response(200)
    assert html =~ "<title>Acme Back Office</title>"

    {:ok, _view, html} = live(conn, "/api/admin")
    assert html =~ "Acme Back Office"
    refute html =~ "Ash Admin"
  end

  test "it does not show a host app link when host_app_path is not set", %{conn: conn} do
    {:ok, view, html} = live(conn, "/api/admin")

    refute html =~ "Back to app"
    refute has_element?(view, ~s|a[href="/dashboard"]|)
  end

  test "it shows a link back to the host app when host_app_path is set", %{conn: conn} do
    {:ok, view, html} = live(conn, "/api/host-app/admin")

    assert html =~ "Back to dashboard"
    assert has_element?(view, ~s|a[href="/dashboard"]|, "Back to dashboard")
  end

  test "it uses a default label for the host app link", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/api/host-app-default/admin")

    assert has_element?(view, ~s|a[href="/dashboard"]|, "Back to app")
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

  test "generates a fresh per-request csp nonce (never the old published constant)" do
    html =
      build_conn()
      |> get("/api/admin")
      |> html_response(200)

    # The previously hardcoded, publicly-known nonce must be gone.
    refute html =~ "ash_admin-Ed55GFnX"

    [_, style_nonce] = Regex.run(~r/<style nonce="([^"]+)"/, html)
    [_, script_nonce] = Regex.run(~r/<script nonce="([^"]+)"/, html)

    # A real, non-trivial nonce is emitted and shared by the inline tags.
    assert byte_size(style_nonce) >= 16
    assert style_nonce == script_nonce
    assert html =~ ~s|<meta name="csp-nonce-style" content="#{style_nonce}"|

    # And it is random per request.
    other =
      build_conn() |> get("/api/admin") |> html_response(200)

    [_, other_nonce] = Regex.run(~r/<style nonce="([^"]+)"/, other)
    refute other_nonce == style_nonce
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

  describe "set_actor" do
    setup do
      post =
        AshAdmin.Test.Post
        |> Ash.Changeset.for_create(:create, %{body: "actor post"})
        |> Ash.create!()

      %{post: post}
    end

    test "clicking the key on the show page sets the record as the actor", %{
      conn: conn,
      post: post
    } do
      pkey = AshAdmin.Helpers.encode_primary_key(post)

      {:ok, view, _html} =
        live(
          conn,
          "/api/admin?domain=Domain&resource=Post&action_type=read&primary_key=#{pkey}"
        )

      view
      |> element("button[phx-click=set_actor]")
      |> render_click()

      domain_name = AshAdmin.Domain.name(AshAdmin.Test.Domain)

      assert_push_event(view, "set_actor", %{
        resource: "Post",
        domain: ^domain_name,
        primary_key: ^pkey
      })
    end

    test "clicking the key in the data table sets the record as the actor", %{
      conn: conn,
      post: post
    } do
      pkey = AshAdmin.Helpers.encode_primary_key(post)

      {:ok, view, _html} =
        live(conn, "/api/admin?domain=Domain&resource=Post&action_type=read")

      view
      |> element("button[phx-click=set_actor][phx-value-pkey=\"#{pkey}\"]")
      |> render_click()

      domain_name = AshAdmin.Domain.name(AshAdmin.Test.Domain)

      assert_push_event(view, "set_actor", %{
        resource: "Post",
        domain: ^domain_name,
        primary_key: ^pkey
      })
    end
  end

  describe "actor controls with the default actor plug" do
    test "toggling authorization is allowed", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/api/admin")

      render_hook(view, "toggle_authorizing", %{})
      assert_push_event(view, "toggle_authorizing", %{})

      render_hook(view, "toggle_actor_paused", %{})
      assert_push_event(view, "toggle_actor_paused", %{})

      render_hook(view, "clear_actor", %{})
      assert_push_event(view, "clear_actor", %{})
    end
  end

  describe "actor controls with a custom actor plug" do
    setup do
      language = Ash.create!(AshAdmin.Test.Language, %{name: "English"})
      profile = Ash.create!(AshAdmin.Test.Profile, %{name: "Laszlo"})

      # Its read policy forbids reads without an actor, and the custom plug sets none.
      link =
        Ash.create!(
          AshAdmin.Test.ProfileLanguage,
          %{profile_id: profile.id, language_id: language.id},
          authorize?: false
        )

      post =
        AshAdmin.Test.Post
        |> Ash.Changeset.for_create(:create, %{body: "actor post"})
        |> Ash.create!()

      %{link: link, post: post}
    end

    defp show_link_path(link) do
      pkey = AshAdmin.Helpers.encode_primary_key(link)

      "/api/custom-actor/admin?domain=ManyToMany&resource=ProfileLanguage" <>
        "&action_type=read&primary_key=#{pkey}"
    end

    test "the actor and authorization controls are not rendered", %{conn: conn, post: post} do
      pkey = AshAdmin.Helpers.encode_primary_key(post)

      {:ok, view, _html} =
        live(conn, "/api/custom-actor/admin?domain=Domain&resource=Post&action_type=read")

      refute has_element?(view, "[phx-click=toggle_authorizing]")
      refute has_element?(view, "[phx-click=toggle_actor_paused]")
      refute has_element?(view, "[phx-click=clear_actor]")
      refute has_element?(view, "[phx-click=set_actor]")

      {:ok, view, _html} =
        live(
          conn,
          "/api/custom-actor/admin?domain=Domain&resource=Post&action_type=read&primary_key=#{pkey}"
        )

      refute has_element?(view, "[phx-click=set_actor]")
    end

    test "authorization is still enforced without any toggling", %{conn: conn, link: link} do
      {:ok, _view, html} = live(conn, show_link_path(link))

      refute html =~ link.id
    end

    test "a toggle_authorizing event does not bypass authorization", %{conn: conn, link: link} do
      {:ok, view, _html} = live(conn, show_link_path(link))

      render_hook(view, "toggle_authorizing", %{})

      refute render_patch(view, show_link_path(link)) =~ link.id
      refute_push_event(view, "toggle_authorizing", %{})
    end

    test "a clear_actor event does not bypass authorization", %{conn: conn, link: link} do
      {:ok, view, _html} = live(conn, show_link_path(link))

      render_hook(view, "clear_actor", %{})

      refute render_patch(view, show_link_path(link)) =~ link.id
      refute_push_event(view, "clear_actor", %{})
    end

    test "a toggle_actor_paused event is ignored", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/api/custom-actor/admin")

      render_hook(view, "toggle_actor_paused", %{})
      refute_push_event(view, "toggle_actor_paused", %{})
    end

    test "a set_actor event does not change the actor", %{conn: conn, post: post} do
      {:ok, view, _html} = live(conn, "/api/custom-actor/admin")

      render_hook(view, "set_actor", %{
        "resource" => "Post",
        "domain" => AshAdmin.Domain.name(AshAdmin.Test.Domain),
        "pkey" => AshAdmin.Helpers.encode_primary_key(post)
      })

      refute_push_event(view, "set_actor", %{})
    end
  end

  describe "actor controls with a custom actor plug that allows them" do
    test "the controls are rendered and take effect", %{conn: conn} do
      language = Ash.create!(AshAdmin.Test.Language, %{name: "French"})
      profile = Ash.create!(AshAdmin.Test.Profile, %{name: "Nadja"})

      link =
        Ash.create!(
          AshAdmin.Test.ProfileLanguage,
          %{profile_id: profile.id, language_id: language.id},
          authorize?: false
        )

      path =
        "/api/custom-actor-controls/admin?domain=ManyToMany&resource=ProfileLanguage" <>
          "&action_type=read&primary_key=#{AshAdmin.Helpers.encode_primary_key(link)}"

      {:ok, view, html} = live(conn, path)

      refute html =~ link.id
      assert has_element?(view, "[phx-click=toggle_authorizing]")

      view
      |> element("#sidebar-actor-desktop ~ div [phx-click=toggle_authorizing]")
      |> render_click()

      assert_push_event(view, "toggle_authorizing", %{authorizing: "false"})
      assert render_patch(view, path) =~ link.id

      {:ok, view, _html} =
        live(
          conn,
          "/api/custom-actor-controls/admin?domain=Domain&resource=Post&action_type=read"
        )

      assert has_element?(view, "[phx-click=set_actor]")
    end
  end

  describe "tenant controls" do
    setup do
      suffix = System.unique_integer([:positive])

      for org <- ["acme", "globex"] do
        AshAdmin.Test.TenantNote
        |> Ash.Changeset.for_create(:create, %{body: "#{org} note #{suffix}"}, tenant: org)
        |> Ash.create!()
      end

      %{acme_note: "acme note #{suffix}", globex_note: "globex note #{suffix}"}
    end

    defp notes_path(prefix),
      do: "/api#{prefix}?domain=Tenants&resource=TenantNote&action_type=read"

    test "with the default actor plug, the tenant can be set", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, notes_path("/admin"))

      render_hook(view, "set_tenant", %{"tenant" => "globex"})
      assert_push_event(view, "set_tenant", %{tenant: "globex"})

      html = render_patch(view, notes_path("/admin"))
      assert html =~ context.globex_note
      refute html =~ context.acme_note

      render_hook(view, "clear_tenant", %{})
      assert_push_event(view, "clear_tenant", %{})
    end

    test "with a custom actor plug, its tenant is used and the controls are not rendered",
         %{conn: conn} = context do
      {:ok, view, html} = live(conn, notes_path("/custom-actor-tenant/admin"))

      assert html =~ context.acme_note
      refute html =~ context.globex_note

      assert has_element?(view, "#sidebar-tenant-desktop", "acme")
      refute has_element?(view, "[phx-click=start_editing_tenant]")
      refute has_element?(view, "[phx-click=clear_tenant]")
      refute has_element?(view, "#sidebar-tenant-desktop form")
    end

    test "with a custom actor plug, the tenant cookie is ignored", %{conn: conn} = context do
      # The plug sets no tenant, as in the getting started guide.
      {:ok, view, html} =
        conn
        |> put_req_cookie("tenant", "globex")
        |> live(notes_path("/custom-actor/admin"))

      refute html =~ context.globex_note
      assert has_element?(view, "#sidebar-tenant-desktop", "No tenant")
    end

    test "with a custom actor plug, tenant events are ignored", %{conn: conn} = context do
      {:ok, view, _html} = live(conn, notes_path("/custom-actor-tenant/admin"))

      render_hook(view, "set_tenant", %{"tenant" => "globex"})
      html = render_patch(view, notes_path("/custom-actor-tenant/admin"))
      assert html =~ context.acme_note
      refute html =~ context.globex_note
      refute_push_event(view, "set_tenant", %{})

      render_hook(view, "clear_tenant", %{})
      refute_push_event(view, "clear_tenant", %{})
      assert render_patch(view, notes_path("/custom-actor-tenant/admin")) =~ context.acme_note

      render_hook(view, "start_editing_tenant", %{})
      refute has_element?(view, "#sidebar-tenant-desktop form")
    end

    test "with a custom actor plug that allows them, the tenant can be set",
         %{conn: conn} = context do
      {:ok, view, html} = live(conn, notes_path("/custom-actor-controls/admin"))

      assert html =~ context.acme_note
      assert has_element?(view, "#sidebar-tenant-desktop [phx-click=start_editing_tenant]")

      render_hook(view, "set_tenant", %{"tenant" => "globex"})
      assert_push_event(view, "set_tenant", %{tenant: "globex"})

      html = render_patch(view, notes_path("/custom-actor-controls/admin"))
      assert html =~ context.globex_note
      refute html =~ context.acme_note
    end
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

  test "a nullable boolean argument renders a select with a nil option", %{conn: conn} do
    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=Domain&resource=Post&action_type=create&action=create_with_flag"
      )

    html = view |> element("select[name='form[flag]']") |> render()

    assert html =~ ~s|<option value="">-</option>|
    assert html =~ ~s|<option value="true">True</option>|
    assert html =~ ~s|<option value="false">False</option>|
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

  # LiveView needs an id on a phx-change form to recover it after a reconnect. The test config
  # raises on one without (`:test_warnings`), so rendering the page is the regression test.
  test "a generic action's form has an id", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/api/admin?domain=Domain&resource=Post&action_type=action&action=echo")

    assert has_element?(view, "form#generic-action-form")
  end

  test "an update action's metadata is shown with the updated record", %{conn: conn} do
    language = Ash.create!(AshAdmin.Test.Language, %{name: "Englsh"})

    {:ok, view, _html} =
      live(
        conn,
        "/api/admin?domain=ManyToMany&resource=Language&action_type=update&action=rename_with_receipt&primary_key=#{language.id}"
      )

    view |> form("#form", form: %{name: "English"}) |> render_submit()

    assert assert_patch(view) =~ "action_type=read"
    assert has_element?(view, "#action-metadata", "renamed to English")
    assert render(view) =~ "English"

    # It belongs to that save, so it's gone once the page moves elsewhere.
    render_patch(view, "/api/admin?domain=ManyToMany&resource=Language&action_type=read")
    refute has_element?(view, "#action-metadata")
  end
end
