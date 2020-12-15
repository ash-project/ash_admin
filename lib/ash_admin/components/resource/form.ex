defmodule AshAdmin.Components.Resource.Form do
  use Surface.LiveComponent

  import AshAdmin.Helpers

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, FieldContext, Label, Select, TextInput}

  data changeset, :any
  data action, :any
  data values, :map, default: nil

  prop resource, :any, required: true
  prop api, :any, required: true
  prop record, :any, default: nil
  prop type, :atom, default: nil

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_action()
     |> assign_changeset()
     |> assign_values()
     |> assign(:initialized, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-10 sm:mt-0">
      <div class="md:grid md:grid-cols-3 md:gap-6">
        <div class="mt-5 md:mt-0 md:col-span-2">
          <Form as="change" for={{ @changeset }} change="validate" submit="save" opts={{autocomplete: false}}>
            <div class="shadow overflow-hidden sm:rounded-md">
              <div class="px-4 py-5 bg-white sm:p-6">
                {{{attributes, flags, bottom_attributes} = attributes(@resource, @action); nil}}
                <div class="grid grid-cols-6 gap-6">
                  <div :if={{Enum.count(actions(@resource, @type)) > 1}} class="col-span-6">
                    <FieldContext name="_action">
                      <Label>Action</Label>
                      <Select form="change" field="_action" selected={{to_name(Ash.Resource.primary_action!(@resource, @type).name)}} options={{ actions(@resource, @type) }} />
                    </FieldContext>
                  </div>
                  <div :for={{attribute <- attributes}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                    <FieldContext name={{attribute.name}}>
                      <Label class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</Label>
                      {{render_attribute_input(assigns, attribute)}}
                      <ErrorTag field={{attribute.name}}/>
                    </FieldContext>
                  </div>
                </div>
                <div :if={{!Enum.empty?(flags)}} class="hidden sm:block" aria-hidden="true">
                  <div class="py-5">
                    <div class="border-t border-gray-200"></div>
                  </div>
                </div>
                <div class="grid grid-cols-6 gap-6" :if={{!Enum.empty?(bottom_attributes)}}>
                  <div :for={{attribute <- flags}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                    <FieldContext name={{attribute.name}}>
                      <Label class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</Label>
                      {{render_attribute_input(assigns, attribute)}}
                      <ErrorTag field={{attribute.name}}/>
                    </FieldContext>
                  </div>
                </div>
                <div :if={{!Enum.empty?(bottom_attributes)}} class="hidden sm:block" aria-hidden="true">
                  <div class="py-5">
                    <div class="border-t border-gray-200"></div>
                  </div>
                </div>
                <div class="grid grid-cols-6 gap-6" :if={{!Enum.empty?(bottom_attributes)}}>
                  <div :for={{attribute <- bottom_attributes}} class={{"col-span-6", "sm:col-span-2": short_text?(@resource, attribute), "sm:col-span-3": !long_text?(@resource, attribute)}}>
                    <FieldContext name={{attribute.name}}>
                      <Label class="block text-sm font-medium text-gray-700">{{to_name(attribute.name)}}</Label>
                      {{render_attribute_input(assigns, attribute)}}
                      <ErrorTag field={{attribute.name}}/>
                    </FieldContext>
                  </div>
                </div>
              </div>
              <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                  {{String.capitalize(to_string(@type))}}
                </button>
              </div>
            </div>
          </Form>
        </div>
      </div>
    </div>
    """
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

  defp render_attribute_input(assigns, %{
         type: Ash.Type.Boolean,
         allow_nil?: false,
         default: default,
         name: name
       }) do
    ~H"""
    <Checkbox form="change" class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded" field={{name}} value={{@values[name] || checkbox_default_value(default)}}/>
    """
  end

  defp render_attribute_input(assigns, %{
         type: Ash.Type.Boolean,
         default: default,
         name: name
       }) do
    ~H"""
    <Select form="change" field={{name}} selected={{@values[name] || checkbox_default_value(default)}} options={{ "Nil": nil, "True": "true", "False": "false"}} />
    """
  end

  defp render_attribute_input(assigns, %{
         type: type,
         name: name,
         default: nil
       })
       when type in [Ash.Type.String, Ash.Type.UUID] do
    ~H"""
    <TextInput form="change" field={{name}} value={{@values[name]}} class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"/>
    """
  end

  defp render_attribute_input(assigns, %{
         type: type,
         name: name,
         default: default
       })
       when type in [Ash.Type.String, Ash.Type.UUID] and
              is_binary(default) do
    ~H"""
    <TextInput form="change" field={{name}} value={{@values[name] || default}} class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"/>
    """
  end

  defp render_attribute_input(assigns, %{
         type: type,
         name: name,
         default: default,
         generated?: generated?
       })
       when type in [Ash.Type.String, Ash.Type.UUID] and
              (is_function(default) or generated?) do
    ~H"""
    <TextInput form="change" field={{name}} value={{@values[name]}} opts={{placeholder: "DEFAULT"}} class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"/>
    """
  end

  defp render_attribute_input(assigns, attribute) do
    ~H"""
    <TextInput form="change" value={{@values[attribute.name]}} field={{attribute.name}} class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"/>
    """
  end

  def handle_event("save", data, socket) do
    changes =
      Enum.reduce(data["change"], %{}, fn {key, val}, acc ->
        attribute = Ash.Resource.attribute(socket.assigns.resource, key)

        if val in [nil, ""] || is_nil(attribute) do
          acc
        else
          Map.put(acc, attribute.name, val)
        end
      end)

    changeset =
      socket.assigns.record
      |> Kernel.||(socket.assigns.resource)
      |> Ash.Changeset.new(changes)
      |> Ash.Changeset.put_context(:action, socket.assigns.action)

    result =
      case socket.assigns.type do
        :create ->
          socket.assigns.api.create(changeset, action: socket.assigns.action)

        :update ->
          socket.assigns.api.update(changeset, action: socket.assigns.action)
      end

    case result do
      {:ok, record} ->
        if Ash.Resource.primary_action(socket.assigns.resource, :update) do
          {:noreply,
           push_redirect(socket,
             to:
               ash_update_path(
                 socket,
                 socket.assigns.api,
                 socket.assigns.resource,
                 record
               )
           )}
        else
          primary_read = Ash.Resource.primary_action!(socket.assigns.resource, :read)

          {:noreply,
           push_redirect(socket,
             to:
               ash_action_path(
                 socket,
                 socket.assigns.api,
                 socket.assigns.resource,
                 :read,
                 primary_read.name
               )
           )}
        end

      {:error, error} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", data, socket) do
    action =
      if data["change"]["_action"] do
        Enum.find(
          Ash.Resource.actions(socket.assigns.resource),
          fn action ->
            action.type == socket.assigns.type &&
              to_string(action.name) == data["change"]["_action"]
          end
        )
      else
        socket.assigns.action
      end

    socket = assign(socket, :action, action)

    changes =
      Enum.reduce(data["change"], %{}, fn {key, val}, acc ->
        attribute = Ash.Resource.attribute(socket.assigns.resource, key)

        if val in [nil, ""] || is_nil(attribute) do
          acc
        else
          Map.put(acc, attribute.name, val)
        end
      end)

    changeset =
      socket.assigns.resource
      |> Ash.Changeset.new(changes)
      |> Ash.Changeset.put_context(:action, socket.assigns.action)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:values, changes)}
  end

  defp checkbox_default_value(default) when default in [true, false] do
    to_string(default)
  end

  defp checkbox_default_value(_), do: "false"

  defp attributes(resource, action) do
    resource
    |> Ash.Resource.attributes()
    |> Enum.filter(& &1.writable?)
    |> Enum.reject(& &1.private?)
    |> only_accepted(action)
    |> sort_attributes(resource)
  end

  defp sort_attributes(attributes, resource) do
    explicitly_sorted =
      resource
      |> AshAdmin.Resource.fields()
      |> Enum.map(fn %{name: name} ->
        Enum.find(attributes, &(&1.name == name))
      end)

    {flags, rest} =
      attributes
      |> Enum.reject(fn attribute ->
        Enum.any?(explicitly_sorted, &(&1.name == attribute.name))
      end)
      |> Enum.split_with(fn attribute ->
        attribute.type == Ash.Type.Boolean
      end)

    {defaults, rest} =
      Enum.split_with(rest, fn attribute ->
        attribute.default
      end)

    auto_sorted =
      Enum.sort_by(rest, fn attribute ->
        {
          # Things with a default go at the bottom
          not is_nil(attribute.default),
          # Long text goes at the bottom
          long_text?(resource, attribute),
          # short text goes at the top
          not short_text?(resource, attribute),
          # Other strings go at the bottom
          attribute.type in [Ash.Type.String, Ash.Type.UUID]
        }
      end)

    sorted_defaults = Enum.sort_by(defaults, &(!&1.type == Ash.Type.Boolean))

    {explicitly_sorted ++ auto_sorted, flags, sorted_defaults}
  end

  defp only_accepted(attributes, %{accept: nil}), do: attributes

  defp only_accepted(attributes, %{accept: accept}) do
    Enum.filter(attributes, &(&1.name in accept))
  end

  defp actions(resource, type) do
    for %{type: ^type} = action <- Ash.Resource.actions(resource) do
      {to_name(action.name), to_string(action.name)}
    end
  end

  defp assign_action(socket) do
    if socket.assigns[:initialized] do
      socket
    else
      assign(
        socket,
        :action,
        Ash.Resource.primary_action!(socket.assigns.resource, socket.assigns.type)
      )
    end
  end

  defp assign_changeset(socket) do
    if socket.assigns[:initialized] do
      socket
    else
      changeset =
        socket.assigns.resource
        |> Ash.Changeset.new()
        |> Ash.Changeset.put_context(:action, socket.assigns.action)

      assign(socket, :changeset, changeset)
    end
  end

  defp assign_values(socket) do
    if is_nil(socket.assigns[:values]) and not is_nil(socket.assigns.record) do
      values =
        Enum.into(
          Ash.Resource.attributes(socket.assigns.resource),
          %{},
          &{&1.name, Map.get(socket.assigns.record, &1.name)}
        )

      assign(socket, :values, values)
    else
      socket
    end
  end
end
