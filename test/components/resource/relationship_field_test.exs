# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.RelationshipFieldTest do
  use ExUnit.Case, async: true

  alias AshAdmin.Components.Resource.RelationshipField

  defmodule Domain do
    @moduledoc false
    use Ash.Domain, validate_config_inclusion?: false

    authorization do
      require_actor?(true)
    end

    resources do
      allow_unregistered?(true)
    end
  end

  defmodule Artist do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    ets do
      private?(true)
    end

    admin do
      label_field :name
    end

    actions do
      defaults([:read])

      create :create do
        accept([:name])
      end
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
    end
  end

  defmodule GuardedArtist do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      authorizers: [Ash.Policy.Authorizer],
      extensions: [AshAdmin.Resource]

    ets do
      private?(true)
    end

    admin do
      label_field :name
    end

    actions do
      defaults([:read])

      create :create do
        accept([:name])
      end
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
    end

    policies do
      policy always() do
        authorize_if(actor_present())
      end
    end
  end

  defp component_socket(artist) do
    {:ok, socket} = RelationshipField.mount(%Phoenix.LiveView.Socket{})

    assigns = %{
      id: "form-artist_id",
      resource: Artist,
      value: artist.id,
      actor: nil,
      authorizing: false,
      tenant: nil
    }

    {:ok, socket} = RelationshipField.update(assigns, socket)
    socket
  end

  defp artist! do
    Artist
    |> Ash.Changeset.for_create(:create, %{name: "Prince"}, actor: nil, authorize?: false)
    |> Ash.create!()
  end

  test "update/2 passes actor options to the label lookup on a require_actor? domain" do
    socket = component_socket(artist!())

    assert socket.assigns.current_label == "Prince"
  end

  test "suggest passes actor options to the search on a require_actor? domain" do
    socket = component_socket(artist!())

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "Pri", "key" => "P"}, socket)

    assert [{"Prince", _id}] = socket.assigns.suggestions
    assert socket.assigns.errors == []
  end

  test "suggest also matches the primary key when the term is a valid primary key" do
    artist = artist!()
    socket = component_socket(artist)

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => artist.id, "key" => "v"}, socket)

    assert [{"Prince", id}] = socket.assigns.suggestions
    assert id == artist.id
  end

  defmodule CompositeArtist do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    ets do
      private?(true)
    end

    admin do
      label_field :name
    end

    actions do
      defaults([:read])

      create :create do
        accept([:code, :region, :name])
      end
    end

    attributes do
      attribute(:code, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:region, :string, primary_key?: true, allow_nil?: false, public?: true)
      attribute(:name, :string, public?: true)
    end
  end

  test "suggest does not match on the primary key when it is composite" do
    CompositeArtist
    |> Ash.Changeset.for_create(:create, %{code: "prn", region: "us", name: "Prince"},
      actor: nil,
      authorize?: false
    )
    |> Ash.create!()

    {:ok, socket} = RelationshipField.mount(%Phoenix.LiveView.Socket{})

    {:ok, socket} =
      RelationshipField.update(
        %{
          id: "form-composite_artist_id",
          resource: CompositeArtist,
          value: nil,
          actor: nil,
          authorizing: false,
          tenant: nil
        },
        socket
      )

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "prn", "key" => "n"}, socket)

    assert socket.assigns.suggestions == []
    assert socket.assigns.errors == []

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "Pri", "key" => "i"}, socket)

    assert [{"Prince", "prn"}] = socket.assigns.suggestions
  end

  test "suggest with a term that is neither a label nor a primary key returns nothing" do
    socket = component_socket(artist!())

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "nobody", "key" => "y"}, socket)

    assert socket.assigns.suggestions == []
    assert socket.assigns.errors == []
  end

  test "Enter with no suggestions does not crash" do
    socket = component_socket(artist!())

    {:noreply, ^socket} =
      RelationshipField.handle_event("suggest", %{"value" => "", "key" => "Enter"}, socket)
  end

  test "Enter with suggestions but nothing highlighted picks the first suggestion" do
    artist = artist!()
    socket = component_socket(artist)

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "Pri", "key" => "P"}, socket)

    {:noreply, socket} =
      RelationshipField.handle_event("suggest", %{"value" => "Pri", "key" => "Enter"}, socket)

    assert socket.assigns.selected_id == artist.id
    assert socket.assigns.current_label == "Prince"
    assert socket.assigns.suggestions == []
  end

  describe "when reads fail" do
    # `GuardedArtist` only authorizes reads when an actor is present, so
    # `authorizing: true` with no actor makes every read fail. This stands in
    # for any forbidden/invalid read (missing tenant, policy denial, ...).
    defp guarded_artist! do
      GuardedArtist
      |> Ash.Changeset.for_create(:create, %{name: "Prince"}, actor: nil, authorize?: false)
      |> Ash.create!()
    end

    defp failing_socket(artist) do
      {:ok, socket} = RelationshipField.mount(%Phoenix.LiveView.Socket{})

      assigns = %{
        id: "form-guarded_artist_id",
        resource: GuardedArtist,
        value: artist.id,
        actor: nil,
        authorizing: true,
        tenant: nil
      }

      {:ok, socket} = RelationshipField.update(assigns, socket)
      socket
    end

    test "update/2 surfaces the error instead of raising and falls back to the typeahead" do
      socket = failing_socket(guarded_artist!())

      assert socket.assigns.field_type == :typeahead
      assert socket.assigns.limited_select_options == []
      assert socket.assigns.current_label == ""
      assert [message] = socket.assigns.errors
      assert message =~ "Could not load Guarded_artist"
    end

    test "suggest surfaces the error instead of raising" do
      socket = failing_socket(guarded_artist!())

      {:noreply, socket} =
        RelationshipField.handle_event("suggest", %{"value" => "Pri", "key" => "P"}, socket)

      assert socket.assigns.suggestions == []
      assert [message] = socket.assigns.errors
      assert message =~ "Could not search Guarded_artist"
    end
  end

  describe "label_string/1" do
    test "renders forbidden fields as a placeholder instead of crashing" do
      assert RelationshipField.label_string(%Ash.ForbiddenField{field: :name, type: :attribute}) ==
               "(forbidden)"
    end

    test "renders ci strings and nil" do
      assert RelationshipField.label_string(%Ash.CiString{string: "Prince"}) == "Prince"
      assert RelationshipField.label_string(nil) == ""
    end
  end
end
