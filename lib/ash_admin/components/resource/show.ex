# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Show do
  @moduledoc false
  use Phoenix.LiveComponent

  require Logger

  alias AshAdmin.Components.Resource.{Helpers.FormatHelper, SensitiveAttribute, Table}
  import AshAdmin.Helpers
  import AshAdmin.CoreComponents

  attr :resource, :any
  attr :record, :any, default: nil
  attr :domain, :any, default: nil
  attr :action, :any
  attr :authorizing, :boolean, default: false
  attr :actor, :any
  attr :tenant, :any
  attr :table, :any, required: true
  attr :prefix, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen pb-20">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_show(assigns, @record, @resource)}
        </div>
      </div>
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_calculations(assigns, @record, @resource)}
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
    assigns = assign(assigns, record: record, resource: resource, title: title, buttons: buttons?)

    ~H"""
    <div class="shadow-lg overflow-hidden sm:rounded-md bg-white">
      <h1 :if={@title} class="pt-2 pl-4 text-lg">{@title}</h1>
      <button
        :if={AshAdmin.Resource.actor?(@resource)}
        class="float-right pt-4 pr-4"
        phx-click="set_actor"
        phx-value-resource={@resource}
        phx-value-domain={@domain}
        phx-value-pkey={encode_primary_key(@record)}
      >
        <.icon name="hero-key" class="h-5 w-5 text-gray-500" />
      </button>
      <div class="px-4 py-5 sm:p-6">
        <div>
          {render_attributes(assigns, @record, @resource)}
          <div :if={@buttons} class="px-4 py-3 text-right sm:px-6">
            <.link
              :if={destroy?(@resource)}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=destroy&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Destroy
            </.link>

            <.link
              :if={update?(@resource)}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@domain)}&resource=#{AshAdmin.Resource.name(@resource)}&action_type=update&table=#{@table}&primary_key=#{encode_primary_key(@record)}"}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Update
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @spec render_calculations(any(), any(), any()) :: Phoenix.LiveView.Rendered.t()
  def render_calculations(assigns, record, resource) do
    assigns = assign(assigns, record: record, resource: resource)

    ~H"""
    <div
      :for={{calculation, calculation_form} <- @calculations}
      class="shadow-lg overflow-hidden sm:rounded-md mb-2 bg-white"
    >
      <div class="px-4 py-5 mt-2">
        <div>{to_name(calculation.name)}</div>
        <div :if={loaded?(@record, calculation.name)}>
          {render_maybe_sensitive_attribute(
            assigns,
            @resource,
            @record,
            calculation
          )}
        </div>
        <div>
          <.form
            :let={form}
            as={calculation.name}
            for={calculation_form}
            phx-change="validate-calculation"
            phx-submit="calculate"
            phx-target={@myself}
          >
            <.input type="hidden" name="calculation" value={calculation.name} />
            {AshAdmin.Components.Resource.Form.render_attributes(
              assigns,
              @resource,
              calculation,
              form
            )}
            <.error :if={is_exception(@calculation_errors[calculation.name])}>
              {Exception.message(@calculation_errors[calculation.name])}
            </.error>
            <.error :if={
              @calculation_errors[calculation.name] &&
                !is_exception(@calculation_errors[calculation.name])
            }>
              {inspect(@calculation_errors[calculation.name])}
            </.error>
            <div class="px-4 py-3 text-right sm:px-6">
              <button
                type="submit"
                class="py-2 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
              >
                Calculate
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp render_relationships(assigns, _record, resource) do
    assigns = assign(assigns, resource: resource)

    ~H"""
    <div
      :for={relationship <- AshAdmin.Components.Resource.Form.relationships(@resource, :show)}
      class="shadow-lg overflow-hidden sm:rounded-md mb-2 bg-white"
    >
      <div class="px-4 py-5 mt-2">
        <div>
          {to_name(relationship.name)}
          <button
            :if={!loaded?(@record, relationship.name)}
            phx-click="load"
            phx-target={@myself}
            phx-value-relationship={relationship.name}
            type="button"
            class="flex py-2 ml-4 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            Load
          </button>
          <button
            :if={loaded?(@record, relationship.name) && relationship.cardinality == :many}
            phx-click="unload"
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

  def mount(socket) do
    assign =
      socket
      |> assign_new(:load_errors, fn -> %{} end)
      |> assign_new(:calculation_errors, fn -> %{} end)

    {:ok, assign}
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_new(:calculations, fn %{resource: resource} ->
      calculations =
        AshAdmin.Resource.show_calculations(resource)

      resource
      |> Ash.Resource.Info.calculations()
      |> Enum.filter(&(&1.name in calculations))
      |> Enum.sort_by(
        &Enum.find_index(calculations, fn name ->
          name == &1.name
        end)
      )
      |> Enum.map(fn calculation ->
        form =
          AshPhoenix.FilterForm.Arguments.new(%{}, calculation.arguments)
          |> to_form()

        {calculation, form}
      end)
    end)
    |> then(&{:ok, &1})
  end

  defp render_relationship_data(assigns, record, %{
         cardinality: :one,
         name: name,
         destination: destination,
         context: context,
         domain: destination_domain
       }) do
    case Map.get(record, name) do
      nil ->
        "None"

      record ->
        assigns =
          assign(assigns,
            record: record,
            name: name,
            destination: destination,
            context: context,
            destination_domain: destination_domain
          )

        ~H"""
        <div class="mb-10">
          {render_attributes(assigns, @record, @destination, @name)}
          <div class="px-4 py-3 text-right sm:px-6">
            <.link
              :if={AshAdmin.Resource.show_action(@destination)}
              navigate={"#{@prefix}?domain=#{AshAdmin.Domain.name(@destination_domain || Ash.Resource.Info.domain(@destination) || @domain)}&resource=#{AshAdmin.Resource.name(@destination)}&table=#{@context[:data_layer][:table]}&primary_key=#{encode_primary_key(@record)}&action_type=read"}
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Show
            </.link>
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
         destination_attribute: destination_attribute,
         domain: destination_domain
       }) do
    data = Map.get(record, name)

    assigns =
      assign(assigns,
        data: data,
        destination: destination,
        destination_domain: destination_domain,
        context: context,
        destination_attribute: destination_attribute,
        relationship_name: name
      )

    ~H"""
    <div class="mb-10 overflow-scroll">
      <Table.table
        data={@data}
        resource={@destination}
        domain={@destination_domain || Ash.Resource.Info.domain(@destination) || @domain}
        table={@context[:data_layer][:table]}
        prefix={@prefix}
        skip={[@destination_attribute]}
        relationship_name={@relationship_name}
      />
    </div>
    """
  end

  defp render_attributes(assigns, record, resource, relationship_name \\ nil) do
    {attributes, flags, bottom_attributes, _} =
      AshAdmin.Components.Resource.Form.attributes(resource, :show)

    assigns =
      assign(assigns,
        record: record,
        resource: resource,
        attributes: attributes,
        flags: flags,
        bottom_attributes: bottom_attributes,
        relationship_name: relationship_name
      )

    ~H"""
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @attributes}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !long_text?(@resource, attribute)
          ])
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>
          {render_maybe_sensitive_attribute(
            assigns,
            @resource,
            @record,
            attribute,
            @relationship_name
          )}
        </div>
      </div>
    </div>
    <div :if={!Enum.empty?(@flags)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div :if={!Enum.empty?(@flags)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @flags}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !long_text?(@resource, attribute)
          ])
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>
          {render_maybe_sensitive_attribute(
            assigns,
            @resource,
            @record,
            attribute,
            @relationship_name
          )}
        </div>
      </div>
    </div>
    <div :if={!Enum.empty?(@bottom_attributes)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div :if={!Enum.empty?(@bottom_attributes)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- @bottom_attributes}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3":
              !(long_text?(@resource, attribute) || Ash.Type.embedded_type?(attribute.type))
          ])
        }
      >
        <div class="block text-sm font-medium text-gray-700">{to_name(attribute.name)}</div>
        <div>
          {render_maybe_sensitive_attribute(
            assigns,
            @resource,
            @record,
            attribute,
            @relationship_name
          )}
        </div>
      </div>
    </div>
    """
  end

  defp render_maybe_sensitive_attribute(
         assigns,
         resource,
         record,
         attribute,
         relationship_name \\ nil
       ) do
    assigns = assign(assigns, attribute: attribute, relationship_name: relationship_name)
    show_sensitive_fields = AshAdmin.Resource.show_sensitive_fields(resource)

    if attribute.sensitive? && not Enum.member?(show_sensitive_fields, attribute.name) do
      ~H"""
      <.live_component
        id={"#{@relationship_name}_#{AshAdmin.Helpers.encode_primary_key(@record)}-#{@attribute.name}"}
        module={SensitiveAttribute}
        value={Map.get(@record, @attribute.name)}
      >
        {render_attribute(assigns, @resource, @record, @attribute, @relationship_name)}
      </.live_component>
      """
    else
      render_attribute(assigns, resource, record, attribute, relationship_name)
    end
  end

  defp render_attribute(assigns, resource, record, attribute, relationship_name, nested? \\ false)

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, type}, name: name} = attribute,
         relationship_name,
         nested?
       ) do
    if Map.get(record, name) in [[], nil] do
      "None"
    else
      assigns =
        assign(assigns,
          resource: resource,
          record: record,
          type: type,
          name: name,
          attribute: attribute,
          relationship_name: relationship_name,
          nested: nested?
        )

      ~H"""
      <%= if @nested do %>
        <ul>
          <li :for={value <- List.wrap(Map.get(@record, @name))} class="mb-4 pb-4 shadow-md">
            {render_attribute(
              assigns,
              @resource,
              Map.put(@record, @name, value),
              %{@attribute | type: @type},
              @relationship_name,
              true
            )}
          </li>
        </ul>
      <% else %>
        <div class="shadow-md border mt-4 mb-4 ml-4">
          <ul>
            <li :for={value <- List.wrap(Map.get(@record, @name))} class="my-4 mb-4 pb-4 shadow-md">
              {render_attribute(
                assigns,
                @resource,
                Map.put(@record, @name, value),
                %{@attribute | type: @type},
                @relationship_name,
                true
              )}
            </li>
          </ul>
        </div>
      <% end %>
      """
    end
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: {:array, Ash.Type.Map}} = attribute,
         relationship_name,
         nested?
       ) do
    render_attribute(
      assigns,
      resource,
      record,
      %{attribute | type: Ash.Type.Map},
      relationship_name,
      nested?
    )
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{type: Ash.Type.Map} = attribute,
         relationship_name,
         _nested?
       ) do
    encoded = Jason.encode!(Map.get(record, attribute.name))

    assigns =
      assign(assigns,
        record: record,
        attribute: attribute,
        encoded: encoded,
        relationship_name: relationship_name
      )

    ~H"""
    <div
      phx-hook="JsonView"
      data-json={@encoded}
      id={"#{@relationship_name}_#{AshAdmin.Helpers.encode_primary_key(@record)}_#{@attribute.name}_json"}
    />
    """
  rescue
    e ->
      Logger.error("Failed to display value:\n#{Exception.format(:error, e, __STACKTRACE__)}")

      "<display error>"
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{name: name, type: Ash.Type.Boolean},
         _relationship_name,
         _
       ) do
    case Map.get(record, name) do
      true ->
        ~H"""
        <.icon name="hero-check" class="h-4 w-4 text-gray-600" />
        """

      false ->
        ~H"""
        <.icon name="hero-x-mark" class="h-4 w-4 text-gray-600" />
        """

      nil ->
        ~H"""
        <.icon name="hero-minus" class="h-4 w-4 text-gray-600" />
        """
    end
  end

  defp render_attribute(
         assigns,
         _resource,
         record,
         %{name: name, type: Ash.Type.Binary},
         _relationship_name,
         _
       ) do
    if Map.get(record, name) do
      ~H"""
      <span class="italic">(binary data)</span>
      """
    else
      "(empty)"
    end
  end

  defp render_attribute(
         assigns,
         resource,
         record,
         %{type: Ash.Type.Union} = attribute,
         relationship_name,
         nested?
       ) do
    case Map.get(record, attribute.name) do
      nil ->
        ""

      %Ash.Union{type: type, value: value} ->
        config = attribute.constraints[:types][type]
        new_attr = %{attribute | type: config[:type], constraints: config[:constraints]}

        render_attribute(
          assigns,
          resource,
          Map.put(record, attribute.name, value),
          new_attr,
          relationship_name,
          nested?
        )
    end
  end

  defp render_attribute(assigns, resource, record, attribute, relationship_name, nested?) do
    if Ash.Type.NewType.new_type?(attribute.type) do
      constraints = Ash.Type.NewType.constraints(attribute.type, attribute.constraints)
      type = Ash.Type.NewType.subtype_of(attribute.type)
      attribute = %{attribute | type: type, constraints: constraints}
      render_attribute(assigns, resource, record, attribute, relationship_name, nested?)
    else
      if Ash.Type.embedded_type?(attribute.type) do
        if Map.get(record, attribute.name) in [nil, []] do
          "None"
        else
          assigns =
            assign(assigns,
              resource: resource,
              record: record,
              attribute: attribute,
              nested: nested?,
              relationship_name: relationship_name
            )

          ~H"""
          <%= if @nested do %>
            <div class="ml-1 pl-2 pr-2">
              {render_attributes(
                assigns,
                Map.get(@record, @attribute.name),
                @attribute.type,
                @relationship_name
              )}
            </div>
          <% else %>
            <div class="shadow-md border mt-4 mb-4 rounded py-2 px-2 ml-1 pl-2 pr-2">
              {render_attributes(
                assigns,
                Map.get(@record, @attribute.name),
                @attribute.type,
                @relationship_name
              )}
            </div>
          <% end %>
          """
        end
      else
        assigns =
          assign(assigns,
            resource: resource,
            record: record,
            attribute: attribute,
            nested: nested?
          )

        case attribute.type do
          Ash.Type.String ->
            cond do
              short_text?(resource, attribute) ->
                value!(Map.get(record, attribute.name))

              long_text?(resource, attribute) ->
                ~H"""
                <textarea
                  rows="3"
                  cols="40"
                  disabled
                  class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                ><%= value!(Map.get(@record, @attribute.name)) %></textarea>
                """

              true ->
                ~H"""
                <textarea
                  rows="1"
                  cols="20"
                  disabled
                  class="resize-y mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                ><%= value!(Map.get(@record, @attribute.name)) %></textarea>
                """
            end

          type
          when type in [
                 Ash.Type.Date,
                 Ash.Type.DateTime,
                 Ash.Type.Time,
                 Ash.Type.NaiveDatetime,
                 Ash.Type.UtcDatetime,
                 Ash.Type.UtcDatetimeUsec
               ] ->
            resource
            |> AshAdmin.Resource.format_fields()
            |> FormatHelper.format_attribute(record, attribute)

          _ ->
            value!(Map.get(record, attribute.name))
        end
      end
    end
  end

  def handle_event("validate-calculation", %{"calculation" => calculation_name} = params, socket) do
    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calculation_name)

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(params[calculation_name], calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  # sobelow_skip ["DOS.StringToAtom"]
  def handle_event("calculate", %{"calculation" => calculation} = event, socket) do
    record = socket.assigns.record
    domain = socket.assigns.domain

    arguments =
      event
      |> Map.get(calculation, [])
      |> Enum.map(fn {attr, value} -> {String.to_atom(attr), value} end)
      # This is a hack, it should not be populated in the form
      # or use used inputs etc.
      |> Enum.reject(fn {_, v} -> v in ["", nil] end)

    calculation = String.to_existing_atom(calculation)

    calculations =
      [{calculation, arguments}]

    case Ash.load(
           record,
           calculations,
           domain: domain,
           actor: socket.assigns[:actor],
           authorize?: socket.assigns[:authorizing]
         ) do
      {:ok, loaded} ->
        {:noreply, assign(socket, record: loaded)}

      {:error, errors} ->
        {:noreply,
         assign(socket,
           calculation_errors: Map.put(socket.assigns.calculation_errors, calculation, errors)
         )}
    end
  end

  def handle_event("load", %{"relationship" => relationship}, socket) do
    record = socket.assigns.record
    domain = socket.assigns.domain
    relationship = String.to_existing_atom(relationship)

    case Ash.load(
           record,
           relationship,
           domain: domain,
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

  # TODO
  # def handle_event("union-type-changed", %{"_target" => path} = params, socket) do
  # new_type = get_in(params, path)
  # # The last part of the path in this case is the field name
  # path =
  #   socket.assigns.form
  #   |> AshPhoenix.Form.parse_path!(:lists.droplast(path))
  #
  # new_union_types = (socket.assigns[:union_types] || %{}) |> Map.put(path, new_type)
  #
  # if AshPhoenix.Form.has_form?(socket.assigns.form, path) do
  #   nested_form = AshPhoenix.Form.get_form(socket.assigns.form, path)
  #
  #   form =
  #     socket.assigns.form
  #     |> AshPhoenix.Form.remove_form(path)
  #     |> AshPhoenix.Form.add_form(path,
  #       params: %{"_new_union_type" => new_type, "_union_type" => new_type},
  #       type: nested_form.type
  #     )
  #
  #   {:noreply, assign(socket, form: form, union_types: new_union_types)}
  # else
  #   {:noreply, assign(socket, union_types: new_union_types)}
  # end
  # end

  def handle_event(event, %{"path" => path, "field" => field} = params, socket)
      when event in ["add_form", "append_value"] do
    to_append =
      case params["union-type"] do
        nil -> nil
        value when value != "" -> %{"_union_type" => value}
        _ -> nil
      end

    [calc_name | decoded_path] =
      path
      |> Plug.Conn.Query.decode()
      |> decoded_to_list()

    path_to_params = decoded_path ++ [field]

    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calc_name)

    keyed_calculations = Map.new(socket.assigns.calculations)
    current_params = keyed_calculations[calculation].params

    new_params =
      case get_in(current_params, path_to_params) do
        nil ->
          put_in(current_params, path_to_params, %{"0" => to_append})

        values ->
          to_place =
            values
            |> Map.keys()
            |> Enum.filter(&String.match?(&1, ~r/[[:digit]]/))
            |> Enum.map(&String.to_integer/1)
            |> case do
              [] -> "0"
              keys -> to_string(Enum.max(keys) + 1)
            end

          put_in(current_params, path_to_params ++ [to_place], to_append)
      end

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(new_params, calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  def handle_event(event, %{"path" => path} = params, socket)
      when event in ["remove_form", "remove_value"] do
    [calc_name | decoded_path] =
      path
      |> Plug.Conn.Query.decode()
      |> decoded_to_list()

    decoded_path =
      if event == "remove_form" do
        decoded_path
      else
        decoded_path ++ [params["field"], params["index"]]
      end

    calculation = Ash.Resource.Info.calculation(socket.assigns.resource, calc_name)

    keyed_calculations = Map.new(socket.assigns.calculations)
    current_params = keyed_calculations[calculation].params
    new_params = pop_in(current_params, decoded_path) |> elem(1)

    arg_form =
      AshPhoenix.FilterForm.Arguments.new(new_params, calculation.arguments)
      |> to_form()

    show_calculations =
      AshAdmin.Resource.show_calculations(socket.assigns.resource)

    calculations =
      socket.assigns.calculations
      |> Map.new()
      |> Map.put(calculation, arg_form)
      |> Enum.sort_by(fn {calc, _form} ->
        Enum.find_index(show_calculations, fn name ->
          name == calc.name
        end)
      end)

    {:noreply, assign(socket, :calculations, calculations)}
  end

  defp loaded?(record, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  defp value!(%{
         __struct__: Postgrex.Range,
         lower: lower,
         upper: upper,
         lower_inclusive: lower_inclusive,
         upper_inclusive: upper_inclusive
       }) do
    lower_str =
      case lower do
        :unbound -> "-∞"
        %DateTime{} = dt -> DateTime.to_string(dt)
        other -> inspect(other)
      end

    upper_str =
      case upper do
        :unbound -> "+∞"
        %DateTime{} = dt -> DateTime.to_string(dt)
        other -> inspect(other)
      end

    lower_bracket = if lower_inclusive, do: "[", else: "("
    upper_bracket = if upper_inclusive, do: "]", else: ")"

    "#{lower_bracket}#{lower_str}, #{upper_str}#{upper_bracket}"
  end

  defp value!(value) do
    if is_binary(value) and !String.valid?(value) do
      "<binary data>"
    else
      data = Phoenix.HTML.Safe.to_iodata(value)
      {:safe, data}
    end
  rescue
    e ->
      Logger.debug("Failed to display value:\n#{Exception.format(:error, e, __STACKTRACE__)}")
      "<display error>"
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
    case AshAdmin.Resource.destroy_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.any?(&(&1.type == :destroy))

      [] ->
        false

      _ ->
        true
    end
  end

  defp update?(resource) do
    case AshAdmin.Resource.update_actions(resource) do
      nil ->
        resource
        |> Ash.Resource.Info.actions()
        |> Enum.any?(&(&1.type == :update))

      [] ->
        false

      _ ->
        true
    end
  end

  defp decoded_to_list(""), do: []

  defp decoded_to_list(value) do
    {key, rest} = Enum.at(value, 0)

    [key | decoded_to_list(rest)]
  end
end
