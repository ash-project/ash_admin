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
  attr :clear_actor, :string, required: true
  attr :api, :any, required: true
  attr :actor_api, :any, required: true
  attr :prefix, :any, required: true

  def actor_select(assigns) do
    ~H"""
    <div id="actor-hook" class="flex items-center mr-5 text-white" phx-hook="Actor">
      <div>
        <span>
          <button phx-click={@toggle_authorizing} type="button">
            <svg
              :if={@authorizing}
              width="1em"
              height="1em"
              viewBox="0 0 16 16"
              fill="white"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                fill-rule="evenodd"
                d="M9.655 8H2.333c-.264 0-.398.068-.471.121a.73.73 0 0 0-.224.296 1.626 1.626 0 0 0-.138.59V14c0 .342.076.531.14.635.064.106.151.18.256.237a1.122 1.122 0 0 0 .436.127l.013.001h7.322c.264 0 .398-.068.471-.121a.73.73 0 0 0 .224-.296 1.627 1.627 0 0 0 .138-.59V9c0-.342-.076-.531-.14-.635a.658.658 0 0 0-.255-.237A1.122 1.122 0 0 0 9.655 8zm.012-1H2.333C.5 7 .5 9 .5 9v5c0 2 1.833 2 1.833 2h7.334c1.833 0 1.833-2 1.833-2V9c0-2-1.833-2-1.833-2zM8.5 4a3.5 3.5 0 1 1 7 0v3h-1V4a2.5 2.5 0 0 0-5 0v3h-1V4z"
              />
            </svg>
            <svg
              :if={!@authorizing}
              width="1em"
              height="1em"
              viewBox="0 0 16 16"
              fill="white"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                fill-rule="evenodd"
                d="M11.5 8h-7a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1h7a1 1 0 0 0 1-1V9a1 1 0 0 0-1-1zm-7-1a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-7zm0-3a3.5 3.5 0 1 1 7 0v3h-1V4a2.5 2.5 0 0 0-5 0v3h-1V4z"
              />
            </svg>
          </button>
          <button :if={@actor} phx-click={@toggle_actor_paused} type="button">
            <svg
              :if={@actor_paused}
              width="1em"
              height="1em"
              viewBox="0 0 16 16"
              fill="white"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M11.596 8.697l-6.363 3.692c-.54.313-1.233-.066-1.233-.697V4.308c0-.63.692-1.01 1.233-.696l6.363 3.692a.802.802 0 0 1 0 1.393z" />
            </svg>
            <svg
              :if={!@actor_paused}
              width="1em"
              height="1em"
              viewBox="0 0 16 16"
              fill="white"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M5.5 3.5A1.5 1.5 0 0 1 7 5v6a1.5 1.5 0 0 1-3 0V5a1.5 1.5 0 0 1 1.5-1.5zm5 0A1.5 1.5 0 0 1 12 5v6a1.5 1.5 0 0 1-3 0V5a1.5 1.5 0 0 1 1.5-1.5z" />
            </svg>
          </button>
          <.link
            :if={@actor}
            class="hover:text-blue-400 hover:underline"
            target={"#{@prefix}?api=#{AshAdmin.Api.name(@actor_api)}&resource=#{AshAdmin.Resource.name(@actor.__struct__)}&tab=show&primary_key=#{encode_primary_key(@actor)}"}
          >
            <%= user_display(@actor) %>
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
        <%= render_actor_link(assigns, @actor_resources) %>
      </div>
    </div>
    """
  end

  defp render_actor_link(assigns, [{api, resource}]) do
    assigns = assign(assigns, api: api, resource: resource)

    ~H"""
    <.link navigate={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=read"}>
      Set <%= AshAdmin.Resource.name(@resource) %>
    </.link>
    """
  end

  defp render_actor_link(assigns, apis_and_resources) do
    assigns = assign(assigns, apis_and_resources: apis_and_resources)

    ~H"""
    <div aria-labelledby="actor-banner">
      <.link
        :for={{{api, resource}, i} <- Enum.with_index(@apis_and_resources)}
        navigate={"#{@prefix}?api=#{AshAdmin.Api.name(api)}&resource=#{AshAdmin.Resource.name(resource)}&action_type=read"}
      >
        Set <%= AshAdmin.Resource.name(resource) %>
        <span :if={i != Enum.count(@apis_and_resources) - 1}>
          |
        </span>
      </.link>
    </div>
    """
  end

  defp user_display(actor) do
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
end
