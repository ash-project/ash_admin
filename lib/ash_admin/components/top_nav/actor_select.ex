# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.ActorSelect do
  @moduledoc false
  use Phoenix.Component

  import AshAdmin.Helpers

  attr :authorizing, :boolean, required: true
  attr :actor_paused, :boolean, required: true
  attr :actor, :any, required: true
  attr :actor_resources, :any, required: true
  attr :toggle_authorizing, :string, required: true
  attr :toggle_actor_paused, :string, required: true
  attr :actor_tenant, :string
  attr :clear_actor, :string, required: true
  attr :domain, :any, required: true
  attr :actor_domain, :any, required: true
  attr :prefix, :any, required: true

  def actor_select(assigns) do
    ~H"""
    <div id="actor-hook" class="flex items-center gap-4 mr-5 text-white" phx-hook="Actor">
      <div>
        <span>
          <button
            class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 mx-1 my-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10"
            phx-click={@toggle_authorizing}
            type="button"
          >
            <span :if={@authorizing}>Authorizing</span>
            <span :if={!@authorizing}>Not Authorizing</span>
          </button>
          <button
            :if={@actor}
            class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 mx-1 my-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10"
            phx-click={@toggle_actor_paused}
            type="button"
          >
            <span :if={@actor_paused}>Actor Paused</span>
            <span :if={!@actor_paused}>Actor Active</span>
          </button>
          <.link
            :if={@actor}
            class="hover:text-blue-400 hover:underline"
            target={"#{@prefix}?domain=#{AshAdmin.Domain.name(@actor_domain)}&resource=#{AshAdmin.Resource.name(@actor.__struct__)}&primary_key=#{encode_primary_key(@actor)}"}
          >
            {user_display(@actor, @actor_tenant)}
          </.link>
          <button :if={@actor} phx-click={@clear_actor} type="button">
            <svg
              width="1em"
              height="1em"
              viewBox="0 0 16 16"
              fill="white"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                fill-rule="evenodd"
                d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"
              />
              <path
                fill-rule="evenodd"
                d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"
              />
            </svg>
          </button>
        </span>
      </div>
      <div :if={!@actor}>
        {render_actor_link(assigns, @actor_resources)}
      </div>
    </div>
    """
  end

  defp render_actor_link(assigns, [{domain, resource}]) do
    assigns = assign(assigns, domain: domain, resource: resource)

    ~H"""
    <.link navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read"}>
      Set {AshAdmin.Resource.name(@resource)}
    </.link>
    """
  end

  defp render_actor_link(assigns, domains_and_resources) do
    assigns = assign(assigns, domains_and_resources: domains_and_resources)

    ~H"""
    <div aria-labelledby="actor-banner">
      <.link
        :for={{{domain, resource}, i} <- Enum.with_index(@domains_and_resources)}
        navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(domain)}&resource=#{AshAdmin.Resource.name(resource)}&action_type=read"}
      >
        Set {AshAdmin.Resource.name(resource)}
        <span :if={i != Enum.count(@domains_and_resources) - 1}>
          |
        </span>
      </.link>
    </div>
    """
  end

  defp user_display(actor, nil) do
    name = AshAdmin.Resource.name(actor.__struct__)

    case Ash.Resource.Info.primary_key(actor.__struct__) do
      [field] ->
        "#{name}: #{Map.get(actor, field)}"

      fields ->
        Enum.map_join(fields, ", ", fn field ->
          "#{field}: #{Map.get(actor, field)}"
        end)
    end
  end

  defp user_display(actor, tenant) do
    user_display(actor, nil) <> " (tenant: #{tenant})"
  end
end
