defmodule AshAdmin.Router do
  @moduledoc """
  Provides LiveView routing for AshAdmin.
  """

  @doc """
  Defines an AshAdmin route.
  It expects the `path` the admin dashboard will be mounted at
  and a set of options.
  ## Options
    * `:apis` - The list of Apis to include in the admin dashboard
  ## Examples
      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import Phoenix.LiveDashboard.Router

        scope "/", MyAppWeb do
          pipe_through [:browser]
          ash_admin "/admin",
            apis: [MyApp.Api1, MyApp.Api2]
        end
      end
  """
  defmacro ash_admin(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]

        apis = opts[:apis]
        Enum.each(apis, &Code.ensure_compiled/1)
        api = List.first(opts[:apis])

        resource =
          api
          |> Ash.Api.resources()
          |> List.first()

        live(
          "/",
          AshAdmin.PageLive,
          :page,
          AshAdmin.Router.__options__(opts, :ash_admin, %{
            "apis" => apis,
            "api" => api,
            "tab" => nil,
            "resource" => nil,
            "action_type" => nil,
            "action_name" => nil
          })
        )

        for api <- apis do
          as =
            api
            |> AshAdmin.Api.name()
            |> String.to_atom()

          live(
            "/#{AshAdmin.Api.name(api)}",
            AshAdmin.PageLive,
            :api_page,
            AshAdmin.Router.__options__(opts, as, %{
              "apis" => apis,
              "api" => api,
              "tab" => "info",
              "resource" => nil,
              "action_type" => nil,
              "action_name" => nil
            })
          )

          for resource <- Ash.Api.resources(api) do
            as =
              api
              |> AshAdmin.Api.name()
              |> Kernel.<>(AshAdmin.Resource.name(resource))
              |> String.to_atom()

            live(
              "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}",
              AshAdmin.PageLive,
              :resource_page,
              AshAdmin.Router.__options__(opts, as, %{
                "apis" => apis,
                "api" => api,
                "tab" => "info",
                "resource" => resource,
                "action_type" => nil,
                "action_name" => nil
              })
            )

            for action <- Ash.Resource.actions(resource) do
              as =
                api
                |> AshAdmin.Api.name()
                |> Kernel.<>(AshAdmin.Resource.name(resource))
                |> Kernel.<>("_#{action.type}")
                |> Kernel.<>("_#{action.name}")
                |> String.to_atom()

              tab =
                if action.type in [:create, :read] do
                  "data"
                else
                  "unknown"
                end

              live(
                "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}/#{action.type}/#{
                  action.name
                }",
                AshAdmin.PageLive,
                :resource_page,
                AshAdmin.Router.__options__(opts, as, %{
                  "apis" => apis,
                  "api" => api,
                  "resource" => resource,
                  "tab" => tab,
                  "action_type" => action.type,
                  "action_name" => action.name
                })
              )
            end
          end
        end
      end
    end
  end

  def __options__(options, as, session) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    csp_nonce_assign_key =
      case options[:csp_nonce_assign_key] do
        nil -> nil
        key when is_atom(key) -> %{img: key, style: key, script: key}
        %{} = keys -> Map.take(keys, [:img, :style, :script])
      end

    [
      session: {__MODULE__, :__session__, [session, csp_nonce_assign_key]},
      private: %{live_socket_path: live_socket_path, csp_nonce_assign_key: csp_nonce_assign_key},
      layout: {AshAdmin.LayoutView, :admin},
      as: as
    ]
  end

  def __session__(conn, session, csp_nonce_assign_key) do
    Map.put(session, "csp_nonces", %{
      img: conn.assigns[csp_nonce_assign_key[:img]],
      style: conn.assigns[csp_nonce_assign_key[:style]],
      script: conn.assigns[csp_nonce_assign_key[:script]]
    })
  end
end
