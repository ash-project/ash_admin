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

  require Logger

  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def mount(
        _params,
        %{
          "prefix" => _prefix
        } = session,
        socket
      ) do
    otp_app = socket.endpoint.config(:otp_app)
    prefix = session["prefix"]
    socket = assign(socket, :prefix, prefix)

    actor_paused =
      if is_nil(session["actor_paused"]) do
        true
      else
        AshAdmin.ActorPlug.session_bool(session["actor_paused"])
      end

    apis = apis(otp_app)

    {:ok,
     socket
     |> Surface.init()
     |> assign(:prefix, prefix)
     |> assign(:primary_key, nil)
     |> assign(:record, nil)
     |> assign(:apis, apis)
     |> assign(:tenant, session["tenant"])
     |> assign(:actor, AshAdmin.ActorPlug.actor_from_session(socket.endpoint, session))
     |> assign(:actor_api, AshAdmin.ActorPlug.actor_api_from_session(socket.endpoint, session))
     |> assign(:actor_resources, actor_resources(apis))
     |> assign(
       :authorizing,
       AshAdmin.ActorPlug.session_bool(session["actor_authorizing"]) || false
     )
     |> assign(:actor_paused, actor_paused)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <TopNav
      id="top_nav"
      apis={@apis}
      api={@api}
      actor_api={@actor_api}
      resource={@resource}
      tenant={@tenant}
      actor_resources={@actor_resources}
      authorizing={@authorizing}
      actor_paused={@actor_paused}
      actor={@actor}
      set_tenant="set_tenant"
      clear_tenant="clear_tenant"
      toggle_authorizing="toggle_authorizing"
      toggle_actor_paused="toggle_actor_paused"
      clear_actor="clear_actor"
      prefix={@prefix}
    />
    <Resource
      :if={@resource}
      id={@resource}
      resource={@resource}
      set_actor="set_actor"
      primary_key={@primary_key}
      record={@record}
      api={@api}
      tab={@tab}
      action_type={@action_type}
      url_path={@url_path}
      params={@params}
      action={@action}
      tenant={@tenant}
      actor={unless @actor_paused, do: @actor}
      authorizing={@authorizing}
      table={@table}
      tables={@tables}
      polymorphic_actions={@polymorphic_actions}
      prefix={@prefix}
    />
    """
  end

  def actor_resources(apis) do
    apis
    |> Enum.flat_map(fn api ->
      api
      |> Ash.Api.Info.resources()
      |> Enum.filter(fn resource ->
        AshAdmin.Helpers.primary_action(resource, :read) && AshAdmin.Resource.actor?(resource)
      end)
      |> Enum.map(fn resource -> {api, resource} end)
    end)
  end

  defp apis(otp_app) do
    otp_app
    |> Application.get_env(:ash_apis)
    |> Enum.filter(&AshAdmin.Api.show?/1)
  end

  defp assign_api(socket, api) do
    api =
      Enum.find(socket.assigns.apis, fn shown_api ->
        AshAdmin.Api.name(shown_api) == api
      end) || Enum.at(socket.assigns.apis, 0)

    assign(socket, :api, api)
  end

  defp assign_resource(socket, resource) do
    if socket.assigns.api do
      resources = Ash.Api.Info.resources(socket.assigns.api)

      resource =
        Enum.find(resources, fn api_resource ->
          AshAdmin.Resource.name(api_resource) == resource
        end) || Enum.at(resources, 0)

      assign(socket, :resource, resource)
    else
      assign(socket, :resource, nil)
    end
  end

  defp assign_action(socket, action, action_type) do
    if socket.assigns.api && socket.assigns.resource do
      action_type =
        case action_type do
          "read" ->
            :read

          "update" ->
            :update

          "create" ->
            :create

          "destroy" ->
            :destroy

          nil ->
            if AshAdmin.Api.default_resource_page(socket.assigns.api) == :primary_read,
              do: :read,
              else: nil
        end

      if action_type do
        action =
          Enum.find(Ash.Resource.Info.actions(socket.assigns.resource), fn resource_action ->
            to_string(resource_action.name) == action && resource_action.type == action_type
          end) || AshAdmin.Helpers.primary_action(socket.assigns.resource, action_type)

        if action do
          assign(socket, action_type: action_type, action: action)
        else
          assign(socket, action_type: nil, action: nil)
        end
      else
        assign(socket, action_type: nil, action: nil)
      end
    else
      assign(socket, :action, nil)
    end
  end

  defp assign_tables(socket, table) do
    if socket.assigns.resource do
      tables =
        if socket.assigns.resource do
          AshAdmin.Resource.polymorphic_tables(socket.assigns.resource, socket.assigns.apis)
        else
          []
        end

      if table && table != "" do
        assign(socket,
          table: table,
          tables: tables,
          polymorphic_actions: AshAdmin.Resource.polymorphic_actions(socket.assigns.resource)
        )
      else
        assign(socket,
          table: Enum.at(tables, 0),
          tables: tables,
          polymorphic_actions: AshAdmin.Resource.polymorphic_actions(socket.assigns.resource)
        )
      end
    else
      assign(socket, table: table, tables: [], polymorphic_actions: [])
    end
  end

  @impl true
  def handle_params(params, url, socket) do
    url = URI.parse(url)

    socket =
      socket
      |> assign_api(params["api"])
      |> assign_resource(params["resource"])
      |> assign_action(params["action"], params["action_type"])
      |> assign_tables(params["table"])
      |> assign(primary_key: params["primary_key"], tab: params["tab"])

    socket =
      if socket.assigns[:primary_key] do
        case decode_primary_key(socket.assigns.resource, socket.assigns[:primary_key]) do
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
              |> Ash.Query.set_tenant(socket.assigns[:tenant])
              |> Ash.Query.for_read(
                AshAdmin.Helpers.primary_action(socket.assigns.resource, :read).name,
                %{},
                actor: actor,
                authorize?: socket.assigns.authorizing
              )
              |> socket.assigns.api.read_one()

            case record do
              {:error, error} ->
                Logger.warn(
                  "Error while loading record on admin dashboard\n: #{Exception.format(:error, error)}"
                )

              {:ok, _} ->
                :ok
            end

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

    #   :error ->
    #     {:error, "Not Found"}
    # end
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
        action = AshAdmin.Helpers.primary_action(resource, :read)

        actor =
          resource
          |> Ash.Query.filter(^pkey_filter)
          |> api.read_one!(action: action)

        api_name = AshAdmin.Api.name(api)
        resource_name = AshAdmin.Resource.name(resource)

        {:noreply,
         socket
         |> push_event(
           "set_actor",
           %{
             resource: to_string(resource_name),
             primary_key: encode_primary_key(actor),
             action: to_string(action.name),
             api: to_string(api_name)
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
