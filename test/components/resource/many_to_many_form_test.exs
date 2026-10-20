# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.ManyToManyFormTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  alias AshAdmin.Test.{Language, Profile, ProfileLanguage}

  setup do
    english = Ash.create!(Language, %{name: "English"})
    german = Ash.create!(Language, %{name: "German"})
    profile = Ash.create!(Profile, %{name: "Laszlo"})

    Ash.create!(ProfileLanguage, %{profile_id: profile.id, language_id: english.id},
      authorize?: false
    )

    pkey = AshAdmin.Helpers.encode_primary_key(profile)

    {:ok, view, _html} =
      live(
        build_conn(),
        "/api/admin?domain=ManyToMany&resource=Profile&action_type=update&primary_key=#{pkey}"
      )

    %{view: view, english: english, german: german, profile: profile}
  end

  test "related records must be loaded before they can be edited", %{view: view} do
    refute has_element?(view, "select[phx-change=select_item]")

    load_languages(view)

    assert has_element?(view, "span", "English")
    assert has_element?(view, "select[phx-change=select_item]")
  end

  test "adding a related record submits its primary key", %{
    view: view,
    english: english,
    german: german,
    profile: profile
  } do
    load_languages(view)
    add_language(view, german)

    assert has_element?(
             view,
             "input[type=hidden][name='form[languages][1][id]'][value='#{german.id}']"
           )

    assert {:error, {:redirect, _}} = view |> form("#form") |> render_submit()

    assert language_ids(profile) == Enum.sort([english.id, german.id])
  end

  test "removing a related record unrelates it", %{view: view, profile: profile} do
    load_languages(view)

    view
    |> element("button[phx-click=remove_form][phx-value-path='form[languages][0]']")
    |> render_click()

    assert {:error, {:redirect, _}} = view |> form("#form") |> render_submit()

    assert language_ids(profile) == []
  end

  test "a forbidden load shows the error instead of crashing", %{view: view} do
    render_click(view, "toggle_authorizing", %{})

    load_languages(view)

    assert render(view) =~ "forbidden"
    refute has_element?(view, "select[phx-change=select_item]")
  end

  defp load_languages(view) do
    view
    |> element("button[phx-click=load][phx-value-relationship=languages]")
    |> render_click()
  end

  defp add_language(view, language) do
    view
    |> element("select[phx-change=select_item]")
    |> render_change(%{"_form-languages-add_add" => language.id})
  end

  defp language_ids(profile) do
    Profile
    |> Ash.get!(profile.id, load: :languages, authorize?: false)
    |> Map.get(:languages)
    |> Enum.map(& &1.id)
    |> Enum.sort()
  end
end
