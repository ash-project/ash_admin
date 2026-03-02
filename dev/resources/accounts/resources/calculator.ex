defmodule Demo.Accounts.Calculator do
  use Ash.Resource,
    domain: Demo.Accounts.Domain,
    extensions: [
      AshAdmin.Resource
    ]

  actions do
    action :add, :integer do
      argument :a, :integer, allow_nil?: false
      argument :b, :integer, allow_nil?: false

      run fn input, _ ->
        {:ok, input.arguments.a + input.arguments.b}
      end
    end

    action :multiply, :integer do
      argument :a, :integer, allow_nil?: false
      argument :b, :integer, allow_nil?: false

      run fn input, _ ->
        {:ok, input.arguments.a * input.arguments.b}
      end
    end

    action :greeting, :string do
      argument :name, :string, allow_nil?: false

      run fn input, _ ->
        {:ok, "Hello, #{input.arguments.name}!"}
      end
    end

    action :current_time do
      run fn _, _ ->
        :ok
      end
    end
  end
end
