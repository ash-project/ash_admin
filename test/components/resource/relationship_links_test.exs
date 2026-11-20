# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Test.Components.Resource.RelationshipLinksTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint AshAdmin.Test.Endpoint

  alias AshAdmin.Components.Resource.{Show, Table}
  alias AshAdmin.Helpers

  alias AshAdmin.Test.{
    Comment,
    Domain,
    IntegerTarget,
    LinkDomain,
    LinkedNote,
    Post,
    StringTarget,
    UnlinkedNote
  }

  @prefix "/api/admin"
  @domains [Domain, LinkDomain]

  defp show_path(domain, resource, primary_key, extra \\ []) do
    Helpers.admin_path(
      @prefix,
      [
        domain: AshAdmin.Domain.name(domain),
        resource: AshAdmin.Resource.name(resource)
      ] ++ extra ++ [primary_key: primary_key, action_type: "read"]
    )
  end

  defp path_for(resource, attribute, value, domains \\ @domains) do
    target =
      resource
      |> Ash.Resource.Info.domain()
      |> then(&Helpers.foreign_key_targets(resource, &1, domains))
      |> Map.get(attribute)

    Helpers.foreign_key_path(@prefix, target, value)
  end

  defp render_table_value(record, resource, field, domains \\ @domains) do
    html =
      render_component(&Table.table/1,
        data: [record],
        resource: resource,
        attributes: [field],
        actions: false,
        domain: Ash.Resource.Info.domain(resource),
        domains: domains,
        table: nil,
        prefix: @prefix
      )

    [_, cell] = Regex.run(~r|<td[^>]*>(.*?)</td>|s, html)
    String.trim(cell)
  end

  defp escaped(path), do: path |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  describe "foreign_key_path/3" do
    test "links a UUID key" do
      post_id = Ash.UUID.generate()
      assert path_for(Comment, :post_id, post_id) == show_path(Domain, Post, post_id)
    end

    test "links an integer key with the encoding the show page decodes" do
      path = path_for(LinkedNote, :integer_target_id, 42)
      %{"primary_key" => encoded} = path |> URI.parse() |> Map.get(:query) |> URI.decode_query()

      assert path == show_path(LinkDomain, IntegerTarget, encoded)
      assert Helpers.decode_primary_key(IntegerTarget, encoded) == {:ok, [id: 42]}
    end

    test "links a string key" do
      assert path_for(LinkedNote, :string_target_id, "abc") ==
               show_path(LinkDomain, StringTarget, "abc")
    end

    test "returns nil for nil, unloaded and forbidden values" do
      assert path_for(Comment, :post_id, nil) == nil
      assert path_for(Comment, :post_id, %Ash.NotLoaded{field: :post_id}) == nil
      assert path_for(Comment, :post_id, %Ash.ForbiddenField{field: :post_id}) == nil
    end

    test "returns nil without a prefix" do
      [target] = Map.values(Helpers.foreign_key_targets(Comment, Domain, @domains))
      assert Helpers.foreign_key_path(nil, target, Ash.UUID.generate()) == nil
    end

    test "returns nil when the attribute is not a belongs_to foreign key" do
      assert path_for(Comment, :body, "text") == nil
    end

    test "returns nil when the destination's domain is not an admin domain" do
      assert path_for(LinkedNote, :post_id, Ash.UUID.generate()) =~ "resource=Post"
      assert path_for(LinkedNote, :hidden_target_id, Ash.UUID.generate()) == nil
    end

    test "returns nil when the destination's domain is not in the admin's domains" do
      assert path_for(LinkedNote, :integer_target_id, 42, [Domain]) == nil
    end

    test "returns nil when link_relationships? is false" do
      assert path_for(UnlinkedNote, :post_id, Ash.UUID.generate()) == nil
    end
  end

  describe "relationship_target/3" do
    test "carries the relationship's polymorphic table" do
      relationship =
        LinkedNote
        |> Ash.Resource.Info.relationship(:post)
        |> Map.put(:context, %{data_layer: %{table: "archived_posts"}})

      target = Helpers.relationship_target(relationship, LinkDomain, @domains)
      post = struct(Post, id: Ash.UUID.generate())

      assert Helpers.record_path(@prefix, target, post) ==
               show_path(Domain, Post, post.id, table: "archived_posts")
    end

    test "falls back to the current domain" do
      relationship =
        Comment
        |> Ash.Resource.Info.relationship(:post)
        |> Map.put(:domain, nil)

      assert %{domain: Domain} = Helpers.relationship_target(relationship, Domain, @domains)
    end
  end

  test "the show page of a comment links its post" do
    post = Ash.create!(Post, %{body: "A post"})
    comment = Ash.create!(Comment, %{body: "A comment", post_id: post.id})

    {:ok, view, _html} = live(build_conn(), show_path(Domain, Comment, comment.id))

    assert has_element?(view, ~s|a[href="#{show_path(Domain, Post, post.id)}"]|, post.id)
  end

  test "the show page links a string foreign key" do
    note = struct(LinkedNote, id: Ash.UUID.generate(), string_target_id: "abc")

    html =
      render_component(Show,
        id: "show",
        resource: LinkedNote,
        record: note,
        domain: LinkDomain,
        domains: @domains,
        table: nil,
        prefix: @prefix,
        actor: nil,
        tenant: nil
      )

    assert html =~ ~s|href="#{escaped(show_path(LinkDomain, StringTarget, "abc"))}"|
  end

  test "a table of comments links to their post" do
    post_id = Ash.UUID.generate()
    comment = struct(Comment, id: Ash.UUID.generate(), body: "A comment", post_id: post_id)

    html = render_table_value(comment, Comment, :post_id)

    assert html =~ ~s|href="#{escaped(show_path(Domain, Post, post_id))}"|
    assert html =~ post_id
  end

  test "a hidden destination renders plain text" do
    hidden_id = Ash.UUID.generate()
    note = struct(LinkedNote, id: Ash.UUID.generate(), hidden_target_id: hidden_id)

    assert render_table_value(note, LinkedNote, :hidden_target_id) == hidden_id
  end

  test "link_relationships? false renders plain text" do
    post_id = Ash.UUID.generate()
    note = struct(UnlinkedNote, id: Ash.UUID.generate(), post_id: post_id)

    assert render_table_value(note, UnlinkedNote, :post_id) == post_id
  end
end
