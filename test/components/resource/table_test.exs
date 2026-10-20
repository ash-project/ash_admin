# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.TableTest do
  use ExUnit.Case, async: false

  alias AshAdmin.Components.Resource.Table
  alias AshAdmin.Test.{Language, ManyToManyDomain, Profile, ProfileLanguage}

  test "relationship display fields load with the admin's authorization setting" do
    language = Ash.create!(Language, %{name: "English"})
    profile = Ash.create!(Profile, %{name: "Laszlo"})

    link =
      Ash.create!(ProfileLanguage, %{profile_id: profile.id, language_id: language.id},
        authorize?: false
      )

    relationship = Ash.Resource.Info.relationship(Profile, :language_link)

    render = fn load_opts ->
      Table.render_attribute(ManyToManyDomain, profile, relationship, [], [], load_opts, nil)
    end

    assert render.(actor: nil, tenant: nil, authorize?: false) == link.id
    assert render.(actor: nil, tenant: nil, authorize?: true) == "..."
  end
end
