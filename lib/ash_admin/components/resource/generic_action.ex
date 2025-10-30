# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.GenericAction do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.Helpers

  attr :resource, :atom
  attr :domain, :atom
  attr :action, :any
  attr :authorizing, :boolean
  attr :actor, :any
  attr :url_path, :any
  attr :params, :any
  attr :tenant, :any, required: true
  attr :table, :any
  attr :prefix, :any

  def render(assigns) do
    ~H"""
    <div class="sm:mt-0 bg-gray-300 min-h-screen">
      <%= if Enum.empty?(@action.arguments) do %>
        <.form
          :let={form}
          as={:form}
          for={@form}
          class="flex flex-row justify-items-center pt-4"
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <div :if={form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
            <ul>
              <li :for={{field, message} <- all_errors(form)}>
                <span :if={field}>
                  {field}:
                </span>
                <span>
                  {message}
                </span>
              </li>
            </ul>
          </div>
          {AshAdmin.Components.Resource.Form.render_attributes(
            assigns,
            @resource,
            @action,
            form
          )}
          <button
            type="submit"
            class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Run
          </button>
        </.form>
      <% else %>
        <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:pt-10 mb-10"></div>
        <div class="md:mt-0 md:col-span-2">
          <div class="shadow-lg overflow-hidden pt-2 sm:rounded-md bg-white">
            <div class="px-4 sm:p-6">
              <.form
                :let={form}
                as={:form}
                for={@form}
                class="flex flex-row"
                phx-change="validate"
                phx-submit="save"
                phx-target={@myself}
              >
                <div :if={form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
                  <ul>
                    <li :for={{field, message} <- all_errors(form)}>
                      <span :if={field}>
                        {field}:
                      </span>
                      <span>
                        {message}
                      </span>
                    </li>
                  </ul>
                </div>
                {AshAdmin.Components.Resource.Form.render_attributes(
                  assigns,
                  @resource,
                  @action,
                  form
                )}
                <div class="px-4 py-3 text-right sm:px-6 my-auto">
                  <button
                    type="submit"
                    class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Run
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>

      <%= case @result do %>
        <% :pending -> %>
        <% :ok -> %>
          Success
        <% {:ok, result} -> %>
          <div class="shadow-lg overflow-auto sm:rounded-md bg-white mx-12 px-8">
            <h1>Success</h1>
            {render_value(assigns, result, @action.returns, @action.constraints)}
          </div>
        <% :error -> %>
          Action failed
      <% end %>
    </div>
    """
  end

  defp render_value(assigns, nil, _, _) do
    ~H"""
    None
    """
  end

  defp render_value(assigns, value, {:array, type}, constraints) do
    assigns = assign(assigns, value: value, type: type, constraints: constraints[:items] || [])

    ~H"""
    <%= for inner_value <- List.wrap(@value) do %>
      {render_value(assigns, inner_value, @type, @constraints)}
      <hr />
    <% end %>
    """
  end

  defp render_value(assigns, value, type, constraints) do
    assigns = assign(assigns, value: value, type: type)

    cond do
      Ash.Type.NewType.new_type?(type) ->
        inner_type = Ash.Type.NewType.subtype_of(type)
        constraints = Ash.Type.NewType.constraints(type, constraints)
        render_value(assigns, value, inner_type, constraints)

      Ash.Type.embedded_type?(type) ->
        AshAdmin.Components.Resource.Show.render_show(assigns, value, type, nil, false)

      (type == Ash.Type.Struct and
         constraints[:instance_of]) && Ash.Resource.Info.resource?(constraints[:instance_of]) ->
        AshAdmin.Components.Resource.Show.render_show(
          assigns,
          value,
          constraints[:instance_of],
          nil,
          false
        )

      type in [Ash.Type.Map, Ash.Type.Keyword, Ash.Type.Struct] ->
        render_keyed_value(assigns, value, type, constraints)

      type == Ash.Type.Union ->
        case value do
          %Ash.Union{type: type, value: value} ->
            type = constraints[type][:type]
            union_constraints = constraints[type][:constraints] || []

            if type do
              render_value(assigns, value, type, union_constraints)
            else
              raw_value(value)
            end

          value ->
            raw_value(value)
        end

      true ->
        raw_value(value)
    end
  end

  defp raw_value(value) when is_binary(value), do: value

  defp raw_value(nil), do: "None"

  defp raw_value(value) do
    inspect(value)
  end

  defp render_keyed_value(assigns, value, _type, constraints) do
    assigns = assign(assigns, value: value, constraints: constraints)

    if (is_map(value) || Keyword.keyword?(value)) && Keyword.keyword?(constraints[:fields]) do
      ~H"""
      <%= for {key, config} <- @constraints[:fields] do %>
        <div class="block text-sm font-medium text-gray-700">
          {to_name(key)}
        </div>
        <div>
          {render_value(assigns, get_key(@value, key), config[:type], config[:constraints])}
        </div>
      <% end %>
      """
    else
      raw_value(value)
    end
  end

  defp get_key(value, key) when is_map(value), do: Map.get(value, key)

  defp get_key(value, key) do
    if Keyword.keyword?(value) do
      value[key]
    else
      nil
    end
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:result, fn -> :pending end)
     |> assign_new(:initialized, fn -> false end)}
  end

  def update(assigns, socket) do
    if assigns[:initialized] do
      {:ok, socket}
    else
      socket = assign(socket, assigns)

      context =
        if table = socket.assigns[:table] do
          %{
            data_layer: %{
              table: table
            }
          }
        else
          %{}
        end

      form =
        AshPhoenix.Form.for_action(socket.assigns.resource, socket.assigns.action.name,
          domain: socket.assigns[:domain],
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant],
          authorize?: socket.assigns[:authorizing],
          context: context
        )

      {:ok, assign(socket, initialized: true, form: form)}
    end
  end

  def handle_event("validate", params, socket) do
    params = params["form"] || %{}
    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    params = params["form"] || %{}

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      :ok -> {:noreply, assign(socket, result: :ok)}
      {:ok, res} -> {:noreply, assign(socket, result: {:ok, res})}
      {:error, form} -> {:noreply, assign(socket, form: form, result: :error)}
    end
  end

  def handle_event("add_form", %{"path" => path} = params, socket) do
    type =
      case params["type"] do
        "lookup" -> :read
        _ -> :create
      end

    form = AshPhoenix.Form.add_form(socket.assigns.form, path, type: type)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("remove_value", %{"path" => path, "field" => field, "index" => index}, socket) do
    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        &remove_value(&1, field, index)
      )

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("append_value", %{"path" => path, "field" => field}, socket) do
    list =
      AshPhoenix.Form.get_form(socket.assigns.form, path)
      |> AshPhoenix.Form.value(String.to_existing_atom(field))
      |> Kernel.||([])
      |> indexed_list()
      |> append_to_and_map(nil)

    params =
      put_in_creating(
        socket.assigns.form.params || %{},
        Enum.map(
          AshPhoenix.Form.parse_path!(socket.assigns.form, path) ++ [field],
          &to_string/1
        ),
        list
      )

    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  defp indexed_list(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
    |> Enum.sort()
    |> Enum.map(&map[to_string(&1)])
  rescue
    _ ->
      List.wrap(map)
  end

  defp indexed_list(other), do: List.wrap(other)

  defp append_to_and_map(list, value) do
    list
    |> Enum.concat([value])
    |> Enum.with_index()
    |> Map.new(fn {v, i} ->
      {"#{i}", v}
    end)
  end

  defp put_in_creating(map, [key], value) do
    Map.put(map || %{}, key, value)
  end

  defp put_in_creating(list, [key | rest], value) when is_list(list) do
    List.update_at(list, String.to_integer(key), &put_in_creating(&1, rest, value))
  end

  defp put_in_creating(map, [key | rest], value) do
    map
    |> Kernel.||(%{})
    |> Map.put_new(key, %{})
    |> Map.update!(key, &put_in_creating(&1, rest, value))
  end

  defp remove_value(form, field, index) do
    current_value =
      form
      |> AshPhoenix.Form.value(String.to_existing_atom(field))
      |> case do
        map when is_map(map) ->
          map

        list ->
          list
          |> List.wrap()
          |> Enum.with_index()
          |> Map.new(fn {value, index} ->
            {to_string(index), value}
          end)
      end

    new_value = Map.delete(current_value, index)

    new_value =
      if new_value == %{} do
        nil
      else
        new_value
      end

    new_params = Map.put(form.params, field, new_value)

    AshPhoenix.Form.validate(form, new_params)
  end

  defp all_errors(form) do
    form
    |> AshPhoenix.Form.errors(for_path: :all)
    |> Enum.flat_map(fn {path, errors} ->
      Enum.map(errors, fn {field, message} ->
        path = List.wrap(path)

        case Enum.reject(path ++ List.wrap(field), &is_nil/1) do
          [] ->
            {nil, message}

          items ->
            {Enum.join(items, "."), message}
        end
      end)
    end)
  end
end
