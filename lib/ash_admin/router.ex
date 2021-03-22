defmodule AshAdmin.Router do
  @moduledoc """
  Provides LiveView routing for AshAdmin.
  """

  @doc """
  Can be used to create a `:browser` pipeline easily if you don't have one.

  By default it is called `:browser`, but you can rename it by supplying an argument,
  for example:

  ```elixir
  defmodule MyAppWeb.Router do
    use Phoenix.Router
    admin_browser_pipeline :something

    scope "/" do

      pipe_through [:something]
      ash_admin "/admin",
        apis: [MyApp.Api1, MyApp.Api2]
    end
  end
  ```
  """
  defmacro admin_browser_pipeline(name \\ :browser) do
    quote do
      import Phoenix.LiveView.Router

      pipeline unquote(name) do
        plug(:accepts, ["html"])
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:put_root_layout, {ThingyWeb.LayoutView, :root})
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end
    end
  end

  @doc """
  Defines an AshAdmin route.
  It expects the `path` the admin dashboard will be mounted at
  and a set of options.
  ## Options
    * `:apis` - The list of Apis to include in the admin dashboard
  ## Examples
      defmodule MyAppWeb.Router do
        use Phoenix.Router

        scope "/" do
          import AshAdmin.Router

          # Make sure you are piping through the browser pipeline
          # If you don't have one, see `admin_browser_pipeline/1`
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
            |> String.downcase()
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
            for {table, alias_part, polymorphic_part} <-
                  AshAdmin.Router.polymorphic_parts(resource, apis) do
              as =
                api
                |> AshAdmin.Api.name()
                |> Kernel.<>(AshAdmin.Resource.name(resource))
                |> Kernel.<>(alias_part)
                |> String.downcase()
                |> String.to_atom()

              live(
                "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{polymorphic_part}",
                AshAdmin.PageLive,
                :resource_page,
                AshAdmin.Router.__options__(opts, as, %{
                  "apis" => apis,
                  "api" => api,
                  "tab" => "info",
                  "resource" => resource,
                  "action_type" => nil,
                  "action_name" => nil,
                  "table" => table
                })
              )

              if Enum.any?(Ash.Resource.Info.actions(resource), &(&1.type == :create)) do
                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("create")
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/create",
                  AshAdmin.PageLive,
                  :resource_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "create",
                    "action_type" => :create,
                    "action_name" => Ash.Resource.Info.primary_action!(resource, :create).name,
                    "table" => table
                  })
                )
              end

              for %{type: :create} = action <- Ash.Resource.Info.actions(resource) do
                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("create")
                  |> Kernel.<>(to_string(action.name))
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/create/#{action.name}",
                  AshAdmin.PageLive,
                  :resource_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "create",
                    "action_type" => :create,
                    "action_name" => action.name,
                    "table" => table
                  })
                )
              end

              if Enum.any?(Ash.Resource.Info.actions(resource), &(&1.type == :update)) do
                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("update")
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/update/:primary_key",
                  AshAdmin.PageLive,
                  :resource_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "update",
                    "action_type" => :update,
                    "action_name" => Ash.Resource.Info.primary_action!(resource, :update).name,
                    "table" => table
                  })
                )

                for %{type: :update} = action <- Ash.Resource.Info.actions(resource) do
                  as =
                    api
                    |> AshAdmin.Api.name()
                    |> Kernel.<>(AshAdmin.Resource.name(resource))
                    |> Kernel.<>(alias_part)
                    |> Kernel.<>("update")
                    |> Kernel.<>(to_string(action.name))
                    |> String.downcase()
                    |> String.to_atom()

                  live(
                    "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                      polymorphic_part
                    }/update/#{action.name}/:primary_key",
                    AshAdmin.PageLive,
                    :resource_page,
                    AshAdmin.Router.__options__(opts, as, %{
                      "apis" => apis,
                      "api" => api,
                      "resource" => resource,
                      "tab" => "update",
                      "action_type" => :update,
                      "action_name" => action.name,
                      "table" => table
                    })
                  )
                end
              end

              if Enum.any?(Ash.Resource.Info.actions(resource), &(&1.type == :destroy)) do
                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("destroy")
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/destroy/:primary_key",
                  AshAdmin.PageLive,
                  :resource_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "destroy",
                    "action_type" => :destroy,
                    "action_name" => Ash.Resource.Info.primary_action!(resource, :destroy).name,
                    "table" => table
                  })
                )

                for %{type: :destroy} = action <- Ash.Resource.Info.actions(resource) do
                  as =
                    api
                    |> AshAdmin.Api.name()
                    |> Kernel.<>(AshAdmin.Resource.name(resource))
                    |> Kernel.<>(alias_part)
                    |> Kernel.<>("destroy")
                    |> Kernel.<>(to_string(action.name))
                    |> String.downcase()
                    |> String.to_atom()

                  live(
                    "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                      polymorphic_part
                    }/destroy/#{action.name}/:primary_key",
                    AshAdmin.PageLive,
                    :resource_page,
                    AshAdmin.Router.__options__(opts, as, %{
                      "apis" => apis,
                      "api" => api,
                      "resource" => resource,
                      "tab" => "destroy",
                      "action_type" => :destroy,
                      "action_name" => action.name,
                      "table" => table
                    })
                  )
                end
              end

              show_action = AshAdmin.Resource.show_action(resource)

              if show_action do
                action =
                  Ash.Resource.Info.action(resource, AshAdmin.Resource.show_action(resource))

                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("_show")
                  |> Kernel.<>("_#{action.name}")
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/show/:primary_key",
                  AshAdmin.PageLive,
                  :show_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "read",
                    "action_type" => :read,
                    "action_name" => action.name,
                    "table" => table
                  })
                )
              end

              for %{type: :read} = action <- Ash.Resource.Info.actions(resource) do
                as =
                  api
                  |> AshAdmin.Api.name()
                  |> Kernel.<>(AshAdmin.Resource.name(resource))
                  |> Kernel.<>(alias_part)
                  |> Kernel.<>("_read")
                  |> Kernel.<>("_#{action.name}")
                  |> String.downcase()
                  |> String.to_atom()

                live(
                  "/#{AshAdmin.Api.name(api)}/#{AshAdmin.Resource.name(resource)}#{
                    polymorphic_part
                  }/#{action.type}/#{action.name}",
                  AshAdmin.PageLive,
                  :resource_page,
                  AshAdmin.Router.__options__(opts, as, %{
                    "apis" => apis,
                    "api" => api,
                    "resource" => resource,
                    "tab" => "data",
                    "action_type" => :read,
                    "action_name" => action.name,
                    "table" => table
                  })
                )
              end
            end
          end
        end
      end
    end
  end

  @doc false
  def __options__(options, as, session) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    [
      session: {__MODULE__, :__session__, [session]},
      private: %{live_socket_path: live_socket_path},
      layout: {AshAdmin.LayoutView, :admin},
      as: as
    ]
  end

  @cookies_to_replicate [
    "tenant",
    "actor_resource",
    "actor_primary_key",
    "actor_action",
    "actor_api",
    "actor_authorizing",
    "actor_paused"
  ]

  @doc false
  def __session__(conn, session) do
    Enum.reduce(@cookies_to_replicate, session, fn cookie, session ->
      case conn.req_cookies[cookie] do
        value when value in [nil, "", "null"] ->
          Map.put(session, cookie, nil)

        value ->
          Map.put(session, cookie, value)
      end
    end)
  end

  @doc false
  def polymorphic_parts(resource, apis) do
    case AshAdmin.Resource.polymorphic_tables(resource, apis) do
      [] ->
        [{nil, "", ""}]

      tables ->
        [{nil, "", ""} | Enum.map(tables, &{&1, &1, "/#{&1}"})]
    end
  end
end
