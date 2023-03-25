defmodule AshAdmin.Test.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_query_params)
  end

  scope "/api" do
    pipe_through(:browser)
    import AshAdmin.Router

    ash_admin("/admin")
  end
end
