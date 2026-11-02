# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Fixtures for `show_relationship_fields`: the fields rendered for each
# relationship on a show page.

defmodule AshAdmin.Test.RelationshipFieldsDomain do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(AshAdmin.Test.RelationshipFieldsAuthor)
    resource(AshAdmin.Test.RelationshipFieldsBook)
    resource(AshAdmin.Test.RelationshipFieldsArticle)
  end
end

defmodule AshAdmin.Test.RelationshipFieldsAuthor do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.RelationshipFieldsDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshAdmin.Resource]

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  admin do
    show_relationship_fields(books: [:title], favorite_book: [:title])
  end

  relationships do
    has_many(:books, AshAdmin.Test.RelationshipFieldsBook,
      public?: true,
      destination_attribute: :author_id
    )

    has_many(:articles, AshAdmin.Test.RelationshipFieldsArticle,
      public?: true,
      destination_attribute: :author_id
    )

    belongs_to(:favorite_book, AshAdmin.Test.RelationshipFieldsBook, public?: true)
  end
end

defmodule AshAdmin.Test.RelationshipFieldsBook do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.RelationshipFieldsDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, public?: true)
    attribute(:isbn, :string, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  relationships do
    belongs_to(:author, AshAdmin.Test.RelationshipFieldsAuthor, public?: true)
  end
end

defmodule AshAdmin.Test.RelationshipFieldsArticle do
  @moduledoc false
  use Ash.Resource,
    domain: AshAdmin.Test.RelationshipFieldsDomain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key(:id)
    attribute(:headline, :string, public?: true)
    attribute(:summary, :string, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  relationships do
    belongs_to(:author, AshAdmin.Test.RelationshipFieldsAuthor, public?: true)
  end
end
