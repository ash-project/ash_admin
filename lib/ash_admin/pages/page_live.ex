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
        Ash.Resource.Info.action(resource, action_name, action_type)
      end

    tables =
      if resource do
        AshAdmin.Resource.polymorphic_tables(resource, apis)
      end

    {:ok,
     socket
     |> Surface.init()
     |> assign(:api, api)
     |> assign(:apis, apis)
     |> assign(:resource, resource)
     |> assign(:action, action)
     |> assign(:primary_key, nil)
     |> assign(:record, nil)
     |> assign(:tab, tab)
     |> assign(:actor_resources, actor_resources(apis))
     |> assign(:tenant, session["tenant"])
     |> assign(:actor, AshAdmin.ActorPlug.actor_from_session(session))
     |> assign(:actor_api, AshAdmin.ActorPlug.actor_api_from_session(session))
     |> assign(
       :authorizing,
       AshAdmin.ActorPlug.session_bool(session["actor_authorizing"]) || false
     )
     |> assign(:actor_paused, actor_paused)
     |> assign(:tables, tables)
     |> assign(:table, session["table"] || Enum.at(tables || [], 0))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <TopNav
      id="top_nav"
      apis={{ @apis }}
      api={{ @api }}
      actor_api={{ @actor_api }}
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
      id={{ @resource }}
      resource={{ @resource }}
      set_actor="set_actor"
      primary_key={{ @primary_key }}
      record={{ @record }}
      api={{ @api }}
      tab={{ @tab }}
      url_path={{ @url_path }}
      params={{ @params }}
      action={{ @action }}
      tenant={{ @tenant }}
      actor={{ unless @actor_paused, do: @actor }}
      authorizing={{ @authorizing }}
      table={{ @table }}
      tables={{ @tables }}
    />
    """
  end

  def actor_resources(apis) do
    apis
    |> Enum.flat_map(fn api ->
      api
      |> Ash.Api.resources()
      |> Enum.filter(&Ash.Resource.Info.primary_action(&1, :read))
      |> Enum.filter(&AshAdmin.Resource.actor?/1)
      |> Enum.map(fn resource -> {api, resource} end)
    end)
  end

  @impl true
  def handle_params(params, url, socket) do
    url = URI.parse(url)

    socket =
      if params["primary_key"] do
        case decode_primary_key(socket.assigns.resource, params["primary_key"]) do
          {:ok, primary_key} ->
            actor =
              if socket.assigns.actor_paused do
                nil
              else
                socket.assigns.actor
              end

            record =
              socket.assigns.resource
              |> Ash.Query.filter(^primary_key)
              |> Ash.Query.load(to_one_relationships(socket.assigns.resource))
              |> socket.assigns.api.read_one(
                action: Ash.Resource.Info.primary_action!(socket.assigns.resource, :read),
                actor: actor,
                authorize?: socket.assigns.authorizing
              )

            socket
            |> assign(:id, params["primary_key"])
            |> assign(:record, record)

          _ ->
            socket
            |> assign(:id, nil)
            |> assign(:record, nil)
        end
      else
        socket
        |> assign(:id, nil)
        |> assign(:record, nil)
      end

    {:noreply,
     socket
     |> assign(:url_path, url.path)
     |> assign(:params, params)}
  end

  defp to_one_relationships(resource) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(&(&1.cardinality == :one))
    |> Enum.map(& &1.name)
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
        %{"resource" => resource, "api" => api, "pkey" => primary_key},
        socket
      )
      when not is_nil(resource) and not is_nil(api) do
    resource = Module.concat([resource])

    case decode_primary_key(resource, primary_key) do
      {:ok, pkey_filter} ->
        api = Module.concat([api])
        action = Ash.Resource.Info.primary_action!(resource, :read)

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
         |> assign(actor: actor, actor_api: api)}
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
       replace: true,
       to:
         self_path(socket.assigns.url_path, socket.assigns.params, %{
           filter: filter_query
         })
     )}
  end
end
