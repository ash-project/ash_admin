defmodule AshAdmin.Components.Resource.Form do
  use Surface.LiveComponent

  import AshAdmin.Helpers

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, FieldContext, Label, Select, TextInput}

  data(changeset, :any)

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(record, :any, default: nil)
  prop(type, :atom, default: nil)
  prop(action, :any)

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset()
     |> assign(:initialized, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-10 sm:mt-0">
      <div class="md:grid md:grid-cols-3 md:gap-6 mx-16 mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {{ render_form(assigns) }}
        </div>
      </div>
    </div>
    """
  end

  defp render_form(assigns, path \\ nil) do
    ~H"""
    <div class="shadow overflow-hidden sm:rounded-md">
      <Form as="action" for={{ :action }} change="change_action">
        <div
          :if={{ is_nil(path) && Enum.count(actions(@resource, @type)) > 1 }}
          class="col-span-6 mr-4 mt-2 float-right overflow-auto"
        >
          <FieldContext name="action">
            <Label>Action</Label>
            <Select selected={{ to_string(@action.name) }} options={{ actions(@resource, @type) }} />
          </FieldContext>
        </div>
        <h1 class="text-lg mt-2 ml-4">
          {{ String.capitalize(to_string(@action.type)) }}</h1>
      </Form>
      <div class="px-4 py-5 bg-white sm:p-6">
        <Form
          as="change"
          for={{ @changeset }}
          change="validate"
          submit="save"
          opts={{ autocomplete: false }}
          :let={{ form: form }}
        >
          {{ {attributes, flags, bottom_attributes} = attributes(@resource, @action)
          nil }}
          <div class="grid grid-cols-6 gap-6">
            <div
              :for={{ attribute <- attributes }}
              class={{
                "col-span-6",
                "sm:col-span-2": short_text?(@resource, attribute),
                "sm:col-span-3": !long_text?(@resource, attribute)
              }}
            >
              <FieldContext name={{ attribute.name }}>
                <Label class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</Label>
                {{ render_attribute_input(assigns, attribute, form) }}
                <ErrorTag field={{ attribute.name }} />
              </FieldContext>
            </div>
          </div>
          <div :if={{ !Enum.empty?(flags) }} class="hidden sm:block" aria-hidden="true">
            <div class="py-5">
              <div class="border-t border-gray-200" />
            </div>
          </div>
          <div class="grid grid-cols-6 gap-6" :if={{ !Enum.empty?(bottom_attributes) }}>
            <div
              :for={{ attribute <- flags }}
              class={{
                "col-span-6",
                "sm:col-span-2": short_text?(@resource, attribute),
                "sm:col-span-3": !long_text?(@resource, attribute)
              }}
            >
              <FieldContext name={{ attribute.name }}>
                <Label class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</Label>
                {{ render_attribute_input(assigns, attribute, form) }}
                <ErrorTag field={{ attribute.name }} />
              </FieldContext>
            </div>
          </div>
          <div :if={{ !Enum.empty?(bottom_attributes) }} class="hidden sm:block" aria-hidden="true">
            <div class="py-5">
              <div class="border-t border-gray-200" />
            </div>
          </div>
          <div class="grid grid-cols-6 gap-6" :if={{ !Enum.empty?(bottom_attributes) }}>
            <div
              :for={{ attribute <- bottom_attributes }}
              class={{
                "col-span-6",
                "sm:col-span-2": short_text?(@resource, attribute),
                "sm:col-span-3": !long_text?(@resource, attribute)
              }}
            >
              <FieldContext name={{ attribute.name }}>
                <Label class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</Label>
                {{ render_attribute_input(assigns, attribute, form) }}
                <ErrorTag field={{ attribute.name }} />
              </FieldContext>
            </div>
          </div>
          <div :if={{ is_nil(path) }} class="px-4 py-3 text-right sm:px-6">
            <button
              type="submit"
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {{ String.capitalize(to_string(@type)) }}
            </button>
          </div>
        </Form>
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

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.Boolean,
          allow_nil?: false,
          name: name
        },
        form
      ) do
    ~H"""
    <Checkbox
      form={{ form }}
      field={{ name }}
      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.Boolean,
          name: name
        },
        form
      ) do
    ~H"""
    <Select form={{ form }} field={{ name }} options={{ Nil: nil, True: "true", False: "false" }} />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: type,
          name: name,
          default: nil
        } = attribute,
        form
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID] do
    ~H"""
    <TextInput
      form={{ form }}
      field={{ name }}
      opts={{ type: text_input_type(attribute) }}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: type,
          name: name,
          default: default
        } = attribute,
        form
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID] and
             is_binary(default) do
    ~H"""
    <TextInput
      form={{ form }}
      field={{ name }}
      value={{ default }}
      opts={{ type: text_input_type(attribute) }}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: type,
          name: name,
          default: default,
          generated?: generated?
        } = attribute,
        form
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID] and
             (is_function(default) or generated?) do
    ~H"""
    <TextInput
      form={{ form }}
      field={{ name }}
      opts={{ placeholder: "DEFAULT", type: text_input_type(attribute) }}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    />
    """
  end

  def render_attribute_input(assigns, attribute, form) do
    ~H"""
    <TextInput
      form={{ form }}
      field={{ attribute.name }}
      opts={{ type: text_input_type(attribute) }}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    />
    """
  end

  defp text_input_type(%{sensitive?: true}), do: "password"
  defp text_input_type(_), do: "text"

  def handle_event("change_action", %{"action" => %{"action" => new_action}}, socket) do
    action =
      Enum.find(
        Ash.Resource.Info.actions(socket.assigns.resource),
        fn action ->
          to_string(action.name) == new_action
        end
      )

    case action.type do
      :create ->
        {:noreply,
         push_redirect(socket,
           to: ash_create_path(socket, socket.assigns.api, socket.assigns.resource)
         )}

      :update ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_update_path(
               socket,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.record,
               action.name
             )
         )}
    end
  end

  def handle_event("save", data, socket) do
    case socket.assigns.action.type do
      :create ->
        socket.assigns.resource
        |> Ash.Changeset.for_create(
          socket.assigns.action.name,
          data["change"],
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> socket.assigns.api.create()
        |> case do
          {:ok, created} ->
            redirect_to(socket, created)

          {:error, %{changeset: changeset}} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :update ->
        socket.assigns.record
        |> Ash.Changeset.for_update(
          socket.assigns.action.name,
          data["change"],
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> socket.assigns.api.update()
        |> case do
          {:ok, updated} ->
            redirect_to(socket, updated)

          {:error, %{changeset: changeset}} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :destroy ->
        socket.assigns.record
        |> Ash.Changeset.for_create(
          socket.assigns.action.name,
          data["change"],
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> socket.assigns.api.destroy()
        |> case do
          :ok ->
            {:noreply,
             socket
             |> redirect(to: ash_admin_path(socket, socket.assigns.api, socket.assigns.resource))}

          {:error, %{changeset: changeset}} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  defp redirect_to(socket, record) do
    show_action = AshAdmin.Resource.show_action(socket.assigns.resource)

    if show_action do
      {:noreply,
       socket
       |> redirect(
         to:
           ash_show_path(
             socket,
             socket.assigns.api,
             socket.assigns.resource,
             record,
             show_action
           )
       )}
    else
      {:noreply,
       socket
       |> redirect(
         to: ash_update_path(socket, socket.assigns.api, socket.assigns.resource, record)
       )}
    end
  end

  def handle_event("validate", data, socket) do
    case socket.assigns.action.type do
      :create ->
        changeset =
          Ash.Changeset.for_create(
            socket.assigns.resource,
            socket.assigns.action.name,
            data["change"],
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}

      :update ->
        changeset =
          Ash.Changeset.for_update(
            socket.assigns.record,
            socket.assigns.action.name,
            data["change"],
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}

      :destroy ->
        changeset =
          Ash.Changeset.for_destroy(
            socket.assigns.record,
            socket.assigns.action.name,
            data["change"],
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def attributes(resource, :show) do
    resource
    |> Ash.Resource.Info.attributes()
    |> sort_attributes(resource)
  end

  def attributes(resource, %{type: :read} = action) do
    action.arguments
    |> Enum.reject(& &1.private?)
    |> sort_attributes(resource)
  end

  def attributes(resource, %{type: :destroy} = action) do
    action.arguments
    |> Enum.reject(& &1.private?)
    |> sort_attributes(resource)
  end

  def attributes(resource, action) do
    attributes =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(& &1.writable?)
      |> Enum.reject(& &1.private?)
      |> only_accepted(action)

    arguments =
      action.arguments
      |> Enum.reject(& &1.private?)

    attributes
    |> Enum.concat(arguments)
    |> sort_attributes(resource)
  end

  defp sort_attributes(attributes, resource) do
    {flags, rest} =
      Enum.split_with(attributes, fn attribute ->
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
          attribute.type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID]
        }
      end)

    sorted_defaults = Enum.sort_by(defaults, &(!&1.type == Ash.Type.Boolean))

    {auto_sorted, flags, sorted_defaults}
  end

  defp only_accepted(attributes, %{accept: nil}), do: attributes

  defp only_accepted(attributes, %{accept: accept}) do
    Enum.filter(attributes, &(&1.name in accept))
  end

  defp actions(resource, type) do
    for %{type: ^type} = action <- Ash.Resource.Info.actions(resource) do
      {to_name(action.name), to_string(action.name)}
    end
  end

  defp assign_changeset(socket) do
    if socket.assigns[:initialized] do
      socket
    else
      changeset =
        if socket.assigns.action.type == :create do
          socket.assigns.resource
          |> Ash.Changeset.for_create(socket.assigns.action.name)
          |> AshPhoenix.hide_errors()
        else
          socket.assigns.record
          |> Ash.Changeset.for_update(socket.assigns.action.name)
          |> AshPhoenix.hide_errors()
        end

      assign(socket, :changeset, changeset)
    end
  end
end
