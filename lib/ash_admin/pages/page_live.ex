defmodule AshAdmin.PageNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule AshAdmin.PageLive do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  import AshAdmin.Helpers
  require Ash.Query
  alias AshAdmin.Components.{Resource, TopNav}

  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def mount(
        _params,
        %{
          "api" => api,
          "apis" => apis,
          "tab" => tab,
          "action_type" => action_type,
          "action_name" => action_name,
          "csp_nonces" => csp_nonces,
          "resource" => resource
        } = session,
        socket
      ) do
    actor_paused =
      if is_nil(session["actor_paused"]) do
        true
      else
        AshAdmin.ActorPlug.session_bool(session["actor_paused"])
      end

    action =
      if action_type && action_name && resource do
        Ash.Resource.action(resource, action_name, action_type)
      end

    {:ok,
     socket
     |> Surface.init()
     |> assign(:api, api)
     |> assign(:apis, apis)
     |> assign(:resource, resource)
     |> assign(:action, action)
     |> assign(:tab, tab)
     |> assign(:csp_nonces, csp_nonces)
     |> assign(:actor_resources, actor_resources(apis))
     |> assign(:tenant, session["tenant"])
     |> assign(:actor, AshAdmin.ActorPlug.actor_from_session(session))
     |> assign(:authorizing, AshAdmin.ActorPlug.session_bool(session["actor_authorizing"]))
     |> assign(:actor_paused, actor_paused)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <TopNav
     id="top_nav"
     apis={{ @apis }}
     api={{ @api }}
     resource={{ @resource }}
     tenant={{ @tenant }}
     actor_resources={{ @actor_resources }}
     authorizing={{ @authorizing }}
     actor_paused={{ @actor_paused }}
     actor={{ @actor }}
     set_tenant="set_tenant"
     clear_tenant="clear_tenant"
     toggle_authorizing="toggle_authorizing"
     toggle_actor_paused="toggle_actor_paused"
     clear_actor="clear_actor"
     />
     <Resource
       :if={{ @resource }}
       resource={{ @resource }}
       set_actor="set_actor"
       api={{ @api }}
       tab={{ @tab }}
       action= {{ @action }}
       tenant= {{ @tenant }}
       actor= {{ unless @actor_paused, do: @actor }}
       authorize= {{ @authorizing }}
     />
    """
  end

  def actor_resources(apis) do
    apis
    |> Enum.flat_map(fn api ->
      api
      |> Ash.Api.resources()
      |> Enum.filter(&Ash.Resource.primary_action(&1, :read))
      |> Enum.filter(&AshAdmin.Resource.actor?/1)
      |> Enum.map(fn resource -> {api, resource} end)
    end)
  end

  @impl true
  def handle_params(params, url, socket) do
    url = URI.parse(url)

    if params["filter"] do
      {:noreply,
       socket
       |> assign(:recover_filter, params["filter"])
       |> assign(:url_path, url.path)
       |> assign(:params, %{filter: params})}
    else
      {:noreply,
       socket
       |> assign(:filter, nil)
       |> assign(:recover_filter, nil)
       |> assign(:url_path, url.path)
       |> assign(:params, %{})}
    end
  end

  @impl true
  def handle_event("toggle_authorizing", _, socket) do
    {:noreply,
     socket
     |> assign(:authorizing, !socket.assigns.authorizing)
     |> push_event("toggle_authorizing", %{authorizing: to_string(!socket.assigns.authorizing)})}
  end

  def handle_event("toggle_actor_paused", _, socket) do
    {:noreply,
     socket
     |> assign(:actor_paused, !socket.assigns.actor_paused)
     |> push_event("toggle_actor_paused", %{actor_paused: to_string(!socket.assigns.actor_paused)})}
  end

  def handle_event("clear_actor", _, socket) do
    push_event(socket, "clear_actor", %{})

    {:noreply,
     socket
     |> assign(:actor, nil)
     |> assign(:actor_paused, true)
     |> assign(:authorizing, false)
     |> push_event("clear_actor", %{})}
  end

  def handle_event(
        "set_actor",
        %{"resource" => resource, "api" => api, "action" => action, "pkey" => primary_key},
        socket
      ) do
    case decode_primary_key(primary_key) do
      {:ok, pkey_filter} ->
        api = Module.concat([api])
        resource = Module.concat([resource])
        action = Ash.Resource.action(resource, String.to_existing_atom(action), :read)

        actor =
          resource
          |> Ash.Query.filter(^pkey_filter)
          |> api.read_one!(action: action)

        {:noreply,
         socket
         |> push_event(
           "set_actor",
           %{
             resource: to_string(resource),
             primary_key: encode_primary_key(actor),
             action: to_string(action.name),
             api: to_string(api)
           }
         )
         |> assign(:actor, actor)}
    end
  end

  def handle_event("set_tenant", data, socket) do
    {:noreply,
     socket
     |> assign(:editing_tenant, false)
     |> assign(:tenant, data["tenant"])
     |> push_event("set_tenant", %{tenant: data["tenant"]})}
  end

  def handle_event("clear_tenant", _, socket) do
    {:noreply,
     socket
     |> assign(:tenant, nil)
     |> push_event("clear_tenant", %{})}
  end

  @impl true
  def handle_info({:filter_builder_value, _filter, filter_query}, socket) do
    {:noreply,
     socket
     |> push_patch(
       to:
         self_path(socket, %{
           filter: filter_query
         })
     )}
  end

  defp self_path(socket, params) do
    socket.assigns.url_path <> "?" <> Plug.Conn.Query.encode(params)
  end
end
