defmodule AshAdmin.Test.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_query_params)
  end

  pipeline(:ash_admin, do: plug(AshAdmin.Router))

  scope "/" do
    pipe_through([:browser, :ash_admin])
    import AshAdmin.Router

    ash_admin("/")
  end
end
