defmodule Demo.Accounts.OfficeLink do
  use Ash.Resource,
    domain: Demo.Accounts.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "office_links"
    repo Demo.Repo
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    attribute :relationship_type, :atom do
      public? true
      allow_nil? false
      constraints one_of: [:parent, :satellite, :partner]
      default :partner
    end
  end

  relationships do
    belongs_to :source_office, Demo.Accounts.Office do
      public? true
      primary_key? true
      allow_nil? false
    end

    belongs_to :destination_office, Demo.Accounts.Office do
      public? true
      primary_key? true
      allow_nil? false
    end
  end
end
