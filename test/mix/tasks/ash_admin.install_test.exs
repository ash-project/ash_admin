defmodule Mix.Tasks.AshAdmin.InstallTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  @router_with_browser """
  defmodule TestWeb.Router do
    use TestWeb, :router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {TestWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end

    scope "/", TestWeb do
      pipe_through :browser
      get "/", PageController, :home
    end
  end
  """

  @router_without_browser """
  defmodule TestWeb.Router do
    use TestWeb, :router

    pipeline :api do
      plug :accepts, ["json"]
    end

    scope "/api", TestWeb do
      pipe_through :api
    end
  end
  """

  @endpoint """
  defmodule TestWeb.Endpoint do
    use Phoenix.Endpoint, otp_app: :test

    plug TestWeb.Router
  end
  """

  describe "with browser pipeline" do
    setup do
      [
        igniter:
          test_project(
            files: %{
              "lib/test_web/endpoint.ex" => @endpoint,
              "lib/test_web/router.ex" => @router_with_browser
            }
          )
          |> Igniter.Project.Application.create_app(Test.Application)
          |> apply_igniter!()
      ]
    end

    test "adds ash_admin route with pipe_through :browser", %{igniter: igniter} do
      igniter
      |> Igniter.compose_task("ash_admin.install", [])
      |> assert_has_patch("lib/test_web/router.ex", """
      + | import AshAdmin.Router
      """)
      |> assert_has_patch("lib/test_web/router.ex", """
      + | ash_admin("/")
      """)
    end

    test "does not add admin_browser_pipeline when browser pipeline exists", %{igniter: igniter} do
      diff =
        igniter
        |> Igniter.compose_task("ash_admin.install", [])
        |> diff(only: "lib/test_web/router.ex")

      refute diff =~ "admin_browser_pipeline"
    end

    test "installation is idempotent", %{igniter: igniter} do
      igniter
      |> Igniter.compose_task("ash_admin.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("ash_admin.install", [])
      |> assert_unchanged("lib/test_web/router.ex")
    end
  end

  describe "without browser pipeline" do
    setup do
      [
        igniter:
          test_project(
            files: %{
              "lib/test_web/endpoint.ex" => @endpoint,
              "lib/test_web/router.ex" => @router_without_browser
            }
          )
          |> Igniter.Project.Application.create_app(Test.Application)
          |> apply_igniter!()
      ]
    end

    test "adds admin_browser_pipeline when no browser pipeline exists", %{igniter: igniter} do
      igniter
      |> Igniter.compose_task("ash_admin.install", [])
      |> assert_has_patch("lib/test_web/router.ex", """
      + | admin_browser_pipeline(:browser)
      """)
    end

    test "adds ash_admin route", %{igniter: igniter} do
      igniter
      |> Igniter.compose_task("ash_admin.install", [])
      |> assert_has_patch("lib/test_web/router.ex", """
      + | ash_admin("/")
      """)
    end

    test "installation is idempotent", %{igniter: igniter} do
      igniter
      |> Igniter.compose_task("ash_admin.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("ash_admin.install", [])
      |> assert_unchanged("lib/test_web/router.ex")
    end
  end
end
