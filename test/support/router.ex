defmodule AshAdmin.Test.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_query_params)
  end

  scope "/api" do
    pipe_through(:browser)
    import AshAdmin.Router

    csp_full = %{
      img: :img_csp_nonce,
      style: :style_csp_nonce,
      script: :script_csp_nonce
    }

    ash_admin("/admin")
    ash_admin("/csp/admin", live_session_name: :ash_admin_csp, csp_nonce_assign_key: :csp_nonce_value)
    ash_admin("/csp-full/admin", live_session_name: :ash_admin_csp_full, csp_nonce_assign_key: csp_full)
  end
end
