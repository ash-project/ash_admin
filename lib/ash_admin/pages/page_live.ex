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

  %{
    "action_name" => nil,
    "action_type" => nil,
    "actor_action" => nil,
    "actor_api" => nil,
    "actor_authorizing" => nil,
    "actor_paused" => nil,
    "actor_primary_key" => nil,
    "actor_resource" => nil,
    "api" => Demo.Accounts.Api,
    "apis" => [Demo.Accounts.Api, Demo.Tickets.Api],
    "resource" => nil,
    "tab" => nil,
    "tenant" => nil
  }

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
        Ash.Resource.action(resource, action_name, action_type)
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
     |> assign(:authorizing, AshAdmin.ActorPlug.session_bool(session["actor_authorizing"]))
     |> assign(:recover_filter, nil)
     |> assign(:actor_paused, actor_paused)
     |> assign(:page_num, 1)}
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
       id={{ @resource }}
       resource={{ @resource }}
       set_actor="set_actor"
      primary_key={{ @primary_key }}
      record={{ @record }}
       api={{ @api }}
       tab={{ @tab }}
       url_path={{ @url_path }}
       params={{ @params }}
       page_params={{ @page_params }}
       page_num={{ @page_num }}
       action= {{ @action }}
       tenant= {{ @tenant }}
       actor= {{ unless @actor_paused, do: @actor }}
       recover_filter={{@recover_filter}}
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

    socket =
      if params["filter"] && socket.assigns[:resource] do
        assign(socket, :recover_filter, params["filter"])
      else
        socket
      end

    socket =
      if params["page"] do
        default_limit =
          socket.assigns[:action] && socket.assigns.action.pagination &&
            socket.assigns.action.pagination.default_limit

        count? =
          socket.assigns[:action] && socket.assigns.action.pagination &&
            socket.assigns.action.pagination.countable

        page_params =
          AshPhoenix.LiveView.page_from_params(params["page"], default_limit, !!count?)

        socket
        |> assign(
          :page_params,
          page_params
        )
        |> assign(:page_num, page_num_from_page_params(page_params))
      else
        socket
        |> assign(:page_params, nil)
        |> assign(:page_num, 1)
      end

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
              |> socket.assigns.api.read_one(
                action: Ash.Resource.primary_action!(socket.assigns.resource, :read),
                actor: actor
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
     |> assign(:params, %{})}
  end

  defp page_num_from_page_params(params) do
    cond do
      !params[:offset] || params[:after] || params[:before] ->
        1

      params[:offset] && params[:limit] ->
        trunc(Float.ceil(params[:offset] / params[:limit])) + 1

      true ->
        nil
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
    case decode_primary_key(socket.assigns.resource, primary_key) do
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
         self_path(socket.assigns.url_path, socket.assigns.params, %{
           filter: filter_query
         })
     )}
  end
end
