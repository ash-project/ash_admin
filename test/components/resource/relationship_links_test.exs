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
    CodeTarget,
    Comment,
    Domain,
    FilteredTarget,
    ForbiddenTarget,
    IntegerTarget,
    LinkDomain,
    LinkedNote,
    PolicyNote,
    Post,
    StrictTarget,
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

  defp targets(resource, domains \\ @domains, auth_opts \\ [authorize?: false]) do
    Helpers.foreign_key_targets(resource, Ash.Resource.Info.domain(resource), domains, auth_opts)
  end

  defp path_for(record, attribute, domains \\ @domains) do
    target = targets(record.__struct__, domains)[attribute]
    Helpers.foreign_key_path(@prefix, target, record)
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
    test "links the loaded related record" do
      post = struct(Post, id: Ash.UUID.generate())
      comment = struct(Comment, post_id: post.id, post: post)

      assert path_for(comment, :post_id) == show_path(Domain, Post, post.id)
    end

    test "links an integer key with the encoding the show page decodes" do
      note =
        struct(LinkedNote, integer_target_id: 42, integer_target: struct(IntegerTarget, id: 42))

      path = path_for(note, :integer_target_id)
      %{"primary_key" => encoded} = path |> URI.parse() |> Map.get(:query) |> URI.decode_query()

      assert path == show_path(LinkDomain, IntegerTarget, encoded)
      assert Helpers.decode_primary_key(IntegerTarget, encoded) == {:ok, [id: 42]}
    end

    test "links a string key" do
      note =
        struct(LinkedNote,
          string_target_id: "abc",
          string_target: struct(StringTarget, id: "abc")
        )

      assert path_for(note, :string_target_id) == show_path(LinkDomain, StringTarget, "abc")
    end

    test "links a key that isn't the destination's primary key to its primary key" do
      target = struct(CodeTarget, id: Ash.UUID.generate(), code: "abc")
      note = struct(LinkedNote, code_target_id: "abc", code_target: target)

      assert path_for(note, :code_target_id) == show_path(LinkDomain, CodeTarget, target.id)
    end

    test "returns nil when the related record is not loaded, missing or forbidden" do
      post_id = Ash.UUID.generate()

      assert path_for(struct(Comment, post_id: post_id), :post_id) == nil
      assert path_for(struct(Comment, post_id: post_id, post: nil), :post_id) == nil

      assert path_for(
               struct(Comment, post_id: post_id, post: %Ash.ForbiddenField{field: :post}),
               :post_id
             ) == nil
    end

    test "returns nil without a prefix" do
      post = struct(Post, id: Ash.UUID.generate())
      [target] = Map.values(targets(Comment))

      assert Helpers.foreign_key_path(nil, target, struct(Comment, post: post)) == nil
    end

    test "returns nil when the attribute is not a belongs_to foreign key" do
      assert path_for(struct(Comment, body: "text"), :body) == nil
    end
  end

  describe "foreign_key_targets/4" do
    test "only keeps destinations shown in the admin" do
      assert Map.has_key?(targets(LinkedNote), :post_id)
      refute Map.has_key?(targets(LinkedNote), :hidden_target_id)
      refute Map.has_key?(targets(LinkedNote, [Domain]), :integer_target_id)
    end

    test "is empty, so nothing is loaded, when link_relationships? is false" do
      assert targets(UnlinkedNote) == %{}
      assert Helpers.link_load(targets(UnlinkedNote)) == []
    end

    test "leaves out destinations the actor can't read when authorizing" do
      actor = %{id: Ash.UUID.generate()}
      authorized = targets(PolicyNote, @domains, actor: actor, authorize?: true)

      refute Map.has_key?(authorized, :forbidden_target_id)
      refute Map.has_key?(authorized, :strict_target_id)
      # A filter policy can still load the record, or `nil` when it's filtered out.
      assert Map.has_key?(authorized, :filtered_target_id)

      assert map_size(targets(PolicyNote)) == 3
    end

    test "keeps a read that loads the linked records from failing on a forbidden destination" do
      actor = %{id: Ash.UUID.generate()}
      forbidden = Ash.create!(ForbiddenTarget, %{}, authorize?: false)
      strict = Ash.create!(StrictTarget, %{}, authorize?: false)
      filtered = Ash.create!(FilteredTarget, %{}, authorize?: false)

      Ash.create!(PolicyNote, %{
        forbidden_target_id: forbidden.id,
        strict_target_id: strict.id,
        filtered_target_id: filtered.id
      })

      auth_opts = [actor: actor, authorize?: true]
      link_load = PolicyNote |> targets(@domains, auth_opts) |> Helpers.link_load()

      assert {:ok, [note]} =
               PolicyNote |> Ash.Query.load(link_load) |> Ash.read(auth_opts)

      assert note.filtered_target == nil
      assert path_for(note, :forbidden_target_id) == nil
    end
  end

  describe "relationship_load/5" do
    alias AshAdmin.Test.{
      RelationshipFieldsAuthor,
      RelationshipFieldsBook,
      RelationshipFieldsDomain
    }

    defp load_for(resource, relationship) do
      Helpers.relationship_load(
        resource,
        Ash.Resource.Info.relationship(resource, relationship),
        RelationshipFieldsDomain,
        [RelationshipFieldsDomain],
        authorize?: false
      )
    end

    test "loads the shown foreign keys of the related records" do
      # The author's `favorite_book_id` is shown on a book's author panel.
      assert {:author, %Ash.Query{load: [favorite_book: _]}} =
               load_for(RelationshipFieldsBook, :author)
    end

    test "skips foreign keys left out of show_relationship_fields" do
      # The author shows only the `title` of its favorite book, not its `author_id`.
      assert load_for(RelationshipFieldsAuthor, :favorite_book) == :favorite_book
    end

    test "skips the key of a to-many relationship that points back to the record" do
      # Each article's `author_id` is the author itself, so its panel hides it.
      assert load_for(RelationshipFieldsAuthor, :articles) == :articles
    end
  end

  describe "link_load/1" do
    test "loads a non primary key reference so it can link to the primary key" do
      target = Ash.create!(CodeTarget, %{code: "abc-#{System.unique_integer()}"})

      note =
        LinkedNote
        |> Ash.create!(%{code_target_id: target.code})
        |> Ash.load!(Helpers.link_load(targets(LinkedNote)))

      assert render_table_value(note, LinkedNote, :code_target_id) =~
               ~s|href="#{escaped(show_path(LinkDomain, CodeTarget, target.id))}"|
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

  test "the comments table loads and links their post" do
    post = Ash.create!(Post, %{body: "A post"})
    Ash.create!(Comment, %{body: "A comment", post_id: post.id})

    {:ok, view, _html} =
      live(build_conn(), "#{@prefix}?domain=Domain&resource=Comment&action_type=read")

    assert render_async(view) =~ ~s|href="#{escaped(show_path(Domain, Post, post.id))}"|
  end

  test "the show page links a string foreign key" do
    note =
      struct(LinkedNote,
        id: Ash.UUID.generate(),
        string_target_id: "abc",
        string_target: struct(StringTarget, id: "abc")
      )

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

    comment =
      struct(Comment,
        id: Ash.UUID.generate(),
        body: "A comment",
        post_id: post_id,
        post: struct(Post, id: post_id)
      )

    html = render_table_value(comment, Comment, :post_id)

    assert html =~ ~s|href="#{escaped(show_path(Domain, Post, post_id))}"|
    assert html =~ post_id
  end

  test "a hidden destination renders plain text" do
    hidden_id = Ash.UUID.generate()

    note =
      struct(LinkedNote,
        id: Ash.UUID.generate(),
        hidden_target_id: hidden_id,
        hidden_target: struct(AshAdmin.Test.HiddenTarget, id: hidden_id)
      )

    assert render_table_value(note, LinkedNote, :hidden_target_id) == hidden_id
  end

  test "link_relationships? false renders plain text" do
    post_id = Ash.UUID.generate()

    note =
      struct(UnlinkedNote,
        id: Ash.UUID.generate(),
        post_id: post_id,
        post: struct(Post, id: post_id)
      )

    assert render_table_value(note, UnlinkedNote, :post_id) == post_id
  end
end
