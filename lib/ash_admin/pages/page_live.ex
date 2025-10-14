# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.PageNotFound do
  @moduledoc false
  defexception [:message, plug_status: 404]
end

defmodule AshAdmin.PageLive do
  @moduledoc false
  use Phoenix.LiveView
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
          "prefix" => prefix
        } = session,
        socket
      ) do
    otp_app = socket.endpoint.config(:otp_app)

    prefix =
      case prefix do
        "/" ->
          session["request_path"]

        _ ->
          request_path = session["request_path"]
          [scope, _] = String.split(request_path, prefix)
          scope <> prefix
      end

    socket = assign(socket, :prefix, prefix)

    domains = domains(otp_app)

    {:ok,
     socket
     |> assign(:prefix, prefix)
     |> assign(:primary_key, nil)
     |> assign(:record, nil)
     |> assign(:domains, domains)
     |> assign(:tenant, session["tenant"])
     |> assign(:editing_tenant, false)
     |> then(fn socket ->
       assign(socket, AshAdmin.ActorPlug.actor_assigns(socket, session))
     end)
     |> assign_new(:actor_domain, fn -> nil end)
     |> assign_new(:actor_resources, fn -> [] end)
     |> assign_new(:authorizing, fn -> true end)
     |> assign_new(:actor_paused, fn -> false end)
     |> assign_new(:actor_tenant, fn -> nil end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <.live_component
        module={TopNav}
        id="top_nav"
        domains={@domains}
        domain={@domain}
        editing_tenant={@editing_tenant}
        actor_domain={@actor_domain}
        actor_tenant={@actor_tenant}
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
      <div class="flex-1">
        <.live_component
          :if={@resource}
          module={Resource}
          id={@resource}
          resource={@resource}
          set_actor="set_actor"
          primary_key={@primary_key}
          record={@record}
          domain={@domain}
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
      </div>
    </div>
    """
  end

  defp domains(otp_app) do
    otp_app
    |> Application.get_env(:ash_domains)
    |> Enum.filter(&AshAdmin.Domain.show?/1)
  end

  defp assign_domain(socket, domain) do
    domain =
      Enum.find(socket.assigns.domains, fn shown_domain ->
        AshAdmin.Domain.name(shown_domain) == domain
      end) || Enum.at(socket.assigns.domains, 0)

    assign(socket, :domain, domain)
  end

  defp assign_resource(socket, resource) do
    if socket.assigns.domain do
      resources = AshAdmin.Domain.show_resources(socket.assigns.domain)

      resource =
        Enum.find(resources, fn domain_resources ->
          AshAdmin.Resource.name(domain_resources) == resource
        end) || Enum.at(resources, 0)

      assign(socket, :resource, resource)
    else
      assign(socket, :resource, nil)
    end
  end

  defp assign_action(socket, action, action_type) do
    requested_action = action

    if socket.assigns.domain && socket.assigns.resource do
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

          "action" ->
            :action

          nil ->
            if AshAdmin.Domain.default_resource_page(socket.assigns.domain) == :primary_read,
              do: :read,
              else: nil
        end

      if action_type do
        available_actions =
          case action_type do
            :read ->
              AshAdmin.Resource.read_actions(socket.assigns.resource)

            :update ->
              AshAdmin.Resource.update_actions(socket.assigns.resource)

            :create ->
              AshAdmin.Resource.create_actions(socket.assigns.resource)

            :destroy ->
              AshAdmin.Resource.destroy_actions(socket.assigns.resource)

            :action ->
              AshAdmin.Resource.generic_actions(socket.assigns.resource)
          end

        action =
          Enum.find(
            available_actions,
            &(to_string(&1) == action)
          )

        if action do
          assign(socket,
            action_type: action_type,
            action: Ash.Resource.Info.action(socket.assigns.resource, action)
          )
        else
          action =
            Ash.Resource.Info.action(socket.assigns.resource, Enum.at(available_actions, 0))

          if requested_action &&
               to_string(action.name) != requested_action do
            raise AshAdmin.Errors.NotFound,
              thing: "action",
              key: requested_action
          end

          assign(socket,
            action_type: action.type,
            action: action
          )
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
          AshAdmin.Resource.polymorphic_tables(socket.assigns.resource, socket.assigns.domains)
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
      |> assign_domain(params["domain"])
      |> assign_resource(params["resource"])
      |> assign_action(params["action"], params["action_type"])
      |> assign_tables(params["table"])
      |> assign(primary_key: params["primary_key"])

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

            show_action =
              AshAdmin.Resource.show_action(socket.assigns.resource)

            record =
              socket.assigns.resource
              |> Ash.Query.filter(^primary_key)
              |> Ash.Query.set_tenant(socket.assigns[:tenant])
              |> Ash.Query.for_read(
                show_action,
                %{},
                actor: actor,
                authorize?: socket.assigns.authorizing
              )
              |> Ash.read_one(domain: socket.assigns.domain)

            record =
              socket.assigns.resource
              |> to_one_relationships(socket.assigns.domain)
              |> Enum.reduce(record, fn
                rel, {:ok, record} ->
                  case Ash.load(record, rel,
                         actor: actor,
                         domain: socket.assigns.domain,
                         tenant: socket.assigns[:tenant],
                         authorize?: socket.assigns.authorizing
                       ) do
                    {:ok, record} ->
                      {:ok, record}

                    {:error, %Ash.Error.Forbidden{}} ->
                      {:ok, record}

                    {:error, error} ->
                      Logger.warning(
                        "Error while loading relationship #{inspect(rel)} on admin dashboard\n: #{Exception.format(:error, error)}"
                      )

                      {:ok, record}
                  end

                _rel, other ->
                  other
              end)

            with {:error, error} <- record do
              Logger.warning(
                "Error while loading record #{inspect(primary_key)}\n: #{Exception.format(:error, error)}"
              )
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
  end

  defp to_one_relationships(resource, domain) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(fn relationship ->
      domain = Ash.Resource.Info.domain(relationship.destination) || relationship.domain || domain
      AshAdmin.Domain.show?(domain) && relationship.cardinality == :one
    end)
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

  def handle_event("start_editing_tenant", _, socket) do
    {:noreply, assign(socket, :editing_tenant, true)}
  end

  def handle_event("stop_editing_tenant", _, socket) do
    {:noreply, assign(socket, :editing_tenant, false)}
  end

  def handle_event(
        "set_actor",
        %{"resource" => resource, "domain" => domain, "pkey" => primary_key},
        socket
      )
      when not is_nil(resource) and not is_nil(domain) do
    resource = Module.concat([resource])

    case decode_primary_key(resource, primary_key) do
      {:ok, pkey_filter} ->
        domain = Module.concat([domain])
        action = AshAdmin.Helpers.primary_action(resource, :read)
        actor_load = AshAdmin.Resource.actor_load(resource)

        actor =
          resource
          |> Ash.Query.filter(^pkey_filter)
          |> Ash.Query.load(actor_load)
          |> Ash.Query.set_tenant(socket.assigns[:tenant])
          |> Ash.read_one!(action: action, authorize?: false, domain: domain)

        domain_name = AshAdmin.Domain.name(domain)
        resource_name = AshAdmin.Resource.name(resource)

        {:noreply,
         socket
         |> push_event(
           "set_actor",
           %{
             resource: to_string(resource_name),
             tenant: socket.assigns[:tenant],
             primary_key: encode_primary_key(actor),
             action: to_string(action.name),
             domain: to_string(domain_name)
           }
         )
         |> assign(actor: actor, actor_domain: domain, actor_tenant: socket.assigns[:tenant])}
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
