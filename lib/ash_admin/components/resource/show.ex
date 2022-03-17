defmodule AshAdmin.Components.Resource.Show do
  @moduledoc false
  use Surface.LiveComponent

  alias Surface.Components.LiveRedirect
  alias AshAdmin.Components.Resource.Table
  alias AshAdmin.Components.HeroIcon
  import AshAdmin.Helpers

  prop(resource, :any)
  prop(record, :any, default: nil)
  prop(api, :any, default: nil)
  prop(action, :any)
  prop(authorizing, :boolean, default: false)
  prop(actor, :any)
  prop(tenant, :any)
  prop(set_actor, :event, required: true)
  prop(table, :any, required: true)
  prop(prefix, :any, required: true)

  data(load_errors, :map, default: %{})

  def render(assigns) do
    ~F"""
    <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen pb-20">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_show(assigns, @record, @resource)}
        </div>
      </div>
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_relationships(assigns, @record, @resource)}
        </div>
      </div>
    </div>
    """
  end

  def render_show(assigns, record, resource, title \\ nil, buttons? \\ true) do
    ~F"""
    <div class="shadow-lg overflow-hidden sm:rounded-md bg-white">
      <h1 :if={title} class="pt-2 pl-4 text-lg">{title}</h1>
      <button
        :if={AshAdmin.Resource.actor?(@resource)}
        class="float-right pt-4 pr-4"
        :on-click={@set_actor}
        phx-value-resource={@resource}
        phx-value-api={@api}
        phx-value-pkey={encode_primary_key(@record)}
      >
      <HeroIcon name="key" class="h-5 w-5 text-gray-500" />
      </button>
      <div class="px-4 py-5 sm:p-6">
        <div>
          {render_attributes(assigns, record, resource)}
          <div :if={buttons?} class="px-4 py-3 text-right sm:px-6">
            <LiveRedirect
              to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=destroy&action=#{AshAdmin.Helpers.primary_action(@resource, :destroy).name}&tab=destroy&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
              :if={destroy?(@resource)}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Destroy
            </LiveRedirect>

            <LiveRedirect
              to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=update&action=#{AshAdmin.Helpers.primary_action(@resource, :update).name}&tab=update&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
              :if={update?(@resource)}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Update
            </LiveRedirect>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_relationships(assigns, _record, resource) do
    ~F"""
    <div
      :for={relationship <- AshAdmin.Components.Resource.Form.relationships(resource, :show)}
      class="shadow-lg overflow-hidden sm:rounded-md mb-2 bg-white"
    >
      <div class="px-4 py-5 mt-2">
        <div>
          {to_name(relationship.name)}
          <button
            :if={!loaded?(@record, relationship.name)}
            :on-click="load"
            phx-target={@myself}
            phx-value-relationship={relationship.name}
            type="button"
            class="flex py-2 ml-4 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            Load
          </button>
          <button
            :if={loaded?(@record, relationship.name) && relationship.cardinality == :many}
            :on-click="unload"
            phx-target={@myself}
            phx-value-relationship={relationship.name}
            type="button"
            class="flex py-2 ml-4 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            Unload
          </button>

          <div :if={loaded?(@record, relationship.name)}>
            {render_relationship_data(assigns, @record, relationship)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_relationship_data(assigns, record, %{
         cardinality: :one,
         name: name,
         destination: destination,
         context: context
       }) do
    case Map.get(record, name) do
      nil ->
        ~F"None"

      record ->
        ~F"""
        <div class="mb-10">
          {render_attributes(assigns, record, destination)}
          <div class="px-4 py-3 text-right sm:px-6">
            <LiveRedirect
              :if={AshAdmin.Resource.show_action(destination)}
              to={"#{@prefix}?api=#{AshAdmin.Api.name(@api)}&resource=#{AshAdmin.Resource.name(@resource)}&tab=show&table=#{context[:data_layer][:table]}&primary_key=#{encode_primary_key(@record)}"}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Show
            </LiveRedirect>
          </div>
        </div>
        """
    end
  end

  defp render_relationship_data(assigns, record, %{
         cardinality: :many,
         name: name,
         destination: destination,
         context: context,
         destination_field: destination_field
       }) do
    data = Map.get(record, name)

    ~F"""
    <div class="mb-10 overflow-scroll">
      <Table
        data={data}
        resource={destination}
        api={@api}
        set_actor={@set_actor}
        table={context[:data_layer][:table]}
        prefix={@prefix}
        skip={[destination_field]}
      />
    </div>
    """
  end

  defp render_attributes(assigns, record, resource) do
    ~F"""
    {{attributes, flags, bottom_attributes, _} =
      AshAdmin.Components.Resource.Form.attributes(resource, :show)

    nil}
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- attributes}
        class={
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !long_text?(resource, attribute)
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>{render_attribute(assigns, resource, record, attribute)}</div>
      </div>
    </div>
    <div :if={!Enum.empty?(flags)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div class="grid grid-cols-6 gap-6" :if={!Enum.empty?(flags)}>
      <div
        :for={attribute <- flags}
        class={
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !long_text?(resource, attribute)
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>{render_attribute(assigns, resource, record, attribute)}</div>
      </div>
    </div>
    <div :if={!Enum.empty?(bottom_attributes)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div class="grid grid-cols-6 gap-6" :if={!Enum.empty?(bottom_attributes)}>
      <div
        :for={attribute <- bottom_attributes}
        class={
          "col-span-6",
          "sm:col-span-2": short_text?(resource, attribute),
          "sm:col-span-3": !(long_text?(resource, attribute) || Ash.Type.embedded_type?(attribute.type))
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>{render_attribute(assigns, resource, record, attribute)}</div>
      </div>
    </div>
    """
  end

  defp render_attribute(assigns, resource, record, attribute, nested? \\ false)

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, type}, name: name} = attribute,
         nested?
       ) do
    all_classes = "mb-4 pb-4 shadow-md"

    if Map.get(record, name) in [[], nil] do
      ~F"""
      None
      """
    else
      if nested? do
        ~F"""
        <ul>
          <li :for={value <- List.wrap(Map.get(record, name))} class={all_classes}>
            {render_attribute(assigns, resource, Map.put(record, name, value), %{attribute | type: type}, true)}
          </li>
        </ul>
        """
      else
        ~F"""
        <div class="shadow-md border mt-4 mb-4 ml-4">
          <ul>
            <li :for={value <- List.wrap(Map.get(record, name))} class={"my-4", all_classes}>
              {render_attribute(assigns, resource, Map.put(record, name, value), %{attribute | type: type}, true)}
            </li>
          </ul>
        </div>
        """
      end
    end
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, Ash.Type.Map}} = attribute,
         nested?
       ) do
    render_attribute(assigns, resource, record, %{attribute | type: Ash.Type.Map}, nested?)
  end

  defp render_attribute(assigns, _resource, record, %{type: Ash.Type.Map} = attribute, _nested?) do
    encoded = Jason.encode!(Map.get(record, attribute.name))

    ~F"""
      <div
      phx-hook="JsonView"
      data-json={encoded}
      id={"_#{AshAdmin.Helpers.encode_primary_key(record)}_#{attribute.name}_json"}
      />
    """
  rescue
    _ ->
      ~F"""
      ...
      """
  end

  defp render_attribute(assigns, _resource, record, %{name: name, type: Ash.Type.Boolean}, _) do
    case Map.get(record, name) do
      true ->
        ~F"""
        <HeroIcon name="check" class="h-4 w-4 text-gray-600" />
        """

      false ->
        ~F"""
        <HeroIcon name="x" class="h-4 w-4 text-gray-600" />
        """

      nil ->
        ~F"""
        <HeroIcon name="minus" class="h-4 w-4 text-gray-600" />
        """
    end
  end

  defp render_attribute(assigns, resource, record, attribute, nested?) do
    if Ash.Type.embedded_type?(attribute.type) do
      both_classes = "ml-1 pl-2 pr-2"

      if Map.get(record, attribute.name) in [nil, []] do
        ~F"""
        None
        """
      else
        if nested? do
          ~F"""
          <div class={both_classes}>
            {render_attributes(assigns, Map.get(record, attribute.name), attribute.type)}
          </div>
          """
        else
          ~F"""
          <div class={"shadow-md border mt-4 mb-4 ml-2 rounded py-2 px-2", both_classes}>
            {render_attributes(assigns, Map.get(record, attribute.name), attribute.type)}
          </div>
          """
        end
      end
    else
      if attribute.type == Ash.Type.String do
        cond do
          short_text?(resource, attribute) ->
            ~F"""
            {value!(Map.get(record, attribute.name))}
            """

          long_text?(resource, attribute) ->
            ~F"""
            <textarea
              rows="3"
              cols="40"
              disabled
              class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
            >{value!(Map.get(record, attribute.name))}</textarea>
            """

          true ->
            ~F"""
            <textarea
              rows="1"
              cols="20"
              disabled
              class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
            >{value!(Map.get(record, attribute.name))}</textarea>
            """
        end
      else
        ~F"{value!(Map.get(record, attribute.name))}"
      end
    end
  end

  def handle_event("load", %{"relationship" => relationship}, socket) do
    record = socket.assigns.record
    api = socket.assigns.api
    relationship = String.to_existing_atom(relationship)

    case api.load(
           record,
           relationship,
           actor: socket.assigns[:actor],
           authorize?: socket.assigns[:authorizing]
         ) do
      {:ok, loaded} ->
        {:noreply, assign(socket, record: loaded)}

      {:error, errors} ->
        {:noreply,
         assign(socket, load_errors: Map.put(socket.assigns.load_errors, relationship, errors))}
    end
  end

  def handle_event("unload", %{"relationship" => relationship}, socket) do
    record = socket.assigns.record
    relationship = String.to_existing_atom(relationship)

    unloaded = Map.put(record, relationship, Map.get(record.__struct__.__struct__, relationship))

    {:noreply, assign(socket, record: unloaded)}
  end

  defp loaded?(record, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  defp value!(value) do
    data = Phoenix.HTML.Safe.to_iodata(value)

    if is_binary(data) and !String.valid?(data) do
      "..."
    else
      data
    end
  rescue
    _ ->
      "..."
  end

  defp short_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :short_text} ->
        true

      _ ->
        false
    end
  end

  defp long_text?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :long_text} ->
        true

      _ ->
        false
    end
  end

  defp destroy?(resource) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.any?(&(&1.type == :destroy))
  end

  defp update?(resource) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.any?(&(&1.type == :update))
  end
end
