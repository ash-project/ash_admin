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
      require_actor? true
    end

    resources do
      allow_unregistered? true
    end
  end

  defmodule Artist do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshAdmin.Resource]

    ets do
      private? true
    end

    admin do
      label_field :name
    end

    actions do
      defaults [:read]

      create :create do
        accept [:name]
      end
    end

    attributes do
      uuid_primary_key :id
      attribute :name, :string, public?: true
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
  end
end
