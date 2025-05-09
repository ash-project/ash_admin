defmodule AshAdmin.Test.AshAdminTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "all resources are shown by default", _ do
    defmodule Domain do
      @moduledoc false
      use Ash.Domain,
        extensions: [AshAdmin.Domain]

      admin do
        show? true
      end

      resources do
        resource(AshAdmin.Test.Post)
        resource(AshAdmin.Test.Comment)
      end
    end

    assert AshAdmin.Domain.show_resources(Domain) === [
             AshAdmin.Test.Post,
             AshAdmin.Test.Comment
           ]
  end

  test "all resources are shown when :* option is selected", _ do
    defmodule Domain do
      @moduledoc false
      use Ash.Domain,
        extensions: [AshAdmin.Domain]

      admin do
        show? true
        show_resources :*
      end

      resources do
        resource(AshAdmin.Test.Post)
        resource(AshAdmin.Test.Comment)
      end
    end

    assert AshAdmin.Domain.show_resources(Domain) === [
             AshAdmin.Test.Post,
             AshAdmin.Test.Comment
           ]
  end

  test "selected resources are shown", _ do
    defmodule Domain do
      @moduledoc false
      use Ash.Domain,
        extensions: [AshAdmin.Domain]

      admin do
        show? true
        show_resources AshAdmin.Test.Post
      end

      resources do
        resource(AshAdmin.Test.Post)
        resource(AshAdmin.Test.Comment)
      end
    end

    assert AshAdmin.Domain.show_resources(Domain) === [
             AshAdmin.Test.Post
           ]
  end

  test "if shown resrouces option not eixsting resource providede error", _ do
    assert_raise(
      Spark.Error.DslError,
      "[AshAdmin.Test.AshAdminTest.Domain]\nadmin -> show_resources:\n  SomeRandom is not a valid resource in AshAdmin.Test.AshAdminTest.Domain",
      fn ->
        defmodule Domain do
          @moduledoc false
          use Ash.Domain,
            extensions: [AshAdmin.Domain]

          admin do
            show? true
            show_resources [AshAdmin.Test.Post, SomeRandom]
          end

          resources do
            resource(AshAdmin.Test.Post)
            resource(AshAdmin.Test.Comment)
          end
        end
      end
    )
  end

  describe "domain grouping" do
    test "domains without group return nil" do
      defmodule DomainNoGroup do
        @moduledoc false
        use Ash.Domain,
          extensions: [AshAdmin.Domain]

        admin do
          show? true
        end

        resources do
          resource(AshAdmin.Test.Post)
        end
      end

      assert AshAdmin.Domain.group(DomainNoGroup) == nil
    end

    test "domains with group return their group value" do
      defmodule DomainWithGroup do
        @moduledoc false
        use Ash.Domain,
          extensions: [AshAdmin.Domain]

        admin do
          show? true
          group :sub_app
        end

        resources do
          resource(AshAdmin.Test.Post)
        end
      end

      assert AshAdmin.Domain.group(DomainWithGroup) == :sub_app
    end

    test "multiple domains with same group are all visible" do
      defmodule FirstGroupedDomain do
        @moduledoc false
        use Ash.Domain,
          extensions: [AshAdmin.Domain]

        admin do
          show? true
          group :sub_app
        end

        resources do
          resource(AshAdmin.Test.Post)
        end
      end

      defmodule SecondGroupedDomain do
        @moduledoc false
        use Ash.Domain,
          extensions: [AshAdmin.Domain]

        admin do
          show? true
          group :sub_app
        end

        resources do
          resource(AshAdmin.Test.Comment)
        end
      end

      assert AshAdmin.Domain.group(FirstGroupedDomain) == :sub_app
      assert AshAdmin.Domain.group(SecondGroupedDomain) == :sub_app
    end
  end
end
