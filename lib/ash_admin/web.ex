defmodule AshAdmin.Web do
  @moduledoc false
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import AshAdmin.CoreComponents
      import AshAdmin.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(unverified_routes())
    end
  end

  defp unverified_routes do
    quote do
      alias Phoenix.LiveView.Socket

      def ash_admin_path(conn_or_socket, path, params \\ %{})

      def ash_admin_path(%Socket{router: phoenix_router} = socket, path, params) do
        prefix = phoenix_router.__live_ash_admin_prefix__()

        Phoenix.VerifiedRoutes.unverified_path(
          socket,
          phoenix_router,
          "#{prefix}#{path}",
          params
        )
      end

      def ash_admin_path(
            %Plug.Conn{private: %{phoenix_router: phoenix_router}} = conn,
            path,
            params
          ) do
        prefix = phoenix_router.__live_ash_admin_prefix__()
        Phoenix.VerifiedRoutes.unverified_path(conn, phoenix_router, "#{prefix}#{path}", params)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
