defmodule AshAdmin.Components.Resource.Form do
  @moduledoc false
  use Surface.LiveComponent

  import AshAdmin.Helpers

  alias Surface.Components.{Context, Form}

  alias Surface.Components.Form.{
    Checkbox,
    ErrorTag,
    FieldContext,
    HiddenInput,
    HiddenInputs,
    Inputs,
    Label,
    Select,
    TextArea,
    TextInput
  }

  data(changeset, :any)
  data(load_errors, :map, default: %{})
  data(targets, :any, default: MapSet.new())
  data(loaded, :any, default: MapSet.new())

  prop(resource, :any, required: true)
  prop(api, :any, required: true)
  prop(record, :any, default: nil)
  prop(type, :atom, default: nil)
  prop(actor, :any, default: nil)
  prop(tenant, :any, default: nil)
  prop(authorizing, :boolean, default: false)
  prop(set_actor, :event, required: true)
  prop(action, :any, required: true)
  prop(table, :any, required: true)
  prop(tables, :any, required: true)
  prop(prefix, :any, required: true)

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset()
     |> assign(:initialized, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {{ render_form(assigns) }}
        </div>
      </div>

      <div :if={{ @type != :create }} class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {{ AshAdmin.Components.Resource.Show.render_show(
            assigns,
            @record,
            @resource,
            "Original Record",
            false
          ) }}
        </div>
      </div>
    </div>
    """
  end

  defp render_form(assigns) do
    ~H"""
    <div class="shadow-lg overflow-hidden sm:rounded-md bg-white">
      <div :if={{ @changeset.action_failed? }} class="ml-4 mt-4 text-red-500">
        <ul>
          <li :for={{ {field, message} <- errors_for(@changeset) }}>
            <span :if={{field}}>
              {{ to_name(field) }}:
            </span>
            <span>
              {{message}}
            </span>
          </li>
        </ul>
      </div>
      <h1 class="text-lg mt-2 ml-4">
        {{ String.capitalize(to_string(@action.type)) }} {{AshAdmin.Resource.name(@resource)}}
      </h1>
      <div class="flex justify-between col-span-6 mr-4 mt-2 overflow-auto px-4">
        <AshAdmin.Components.Resource.SelectTable
          resource={{ @resource }}
          on_change="change_table"
          table={{ @table }}
          tables={{ @tables }}
        />
        <Form
          as="action"
          for={{ :action }}
          change="change_action"
          :if={{ Enum.count(actions(@resource, @type)) > 1 }}
          opts={{id: @id <> "_action_form"}}
        >
          <FieldContext name="action">
            <Label>Action</Label>
            <Select selected={{ to_string(@action.name) }} options={{ actions(@resource, @type) }} />
          </FieldContext>
        </Form>
      </div>
      <div class="px-4 py-5 sm:p-6">
        <Form
          as="change"
          for={{ @changeset }}
          change="validate"
          submit="save"
          opts={{ autocomplete: false, id: @id <> "_form" }}
          :let={{ form: form }}
        >
          <input hidden phx-hook="FormChange" id="resource_form">
          <HiddenInputs for={{form}}/>
          {{ render_attributes(assigns, @resource, @action, form) }}
          <div class="px-4 py-3 text-right sm:px-6">
            <button
              type="submit"
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {{ save_button_text(@type) }}
            </button>
          </div>
        </Form>
      </div>
    </div>
    """
  end

  defp errors_for(changeset) do
    changeset
    |> AshPhoenix.transform_errors(fn
      _, %{class: :forbidden} ->
        {nil, "Forbidden", []}

      _, other ->
        other
    end)
    |> AshPhoenix.errors_for(as: :simple)
  end

  defp save_button_text(:update), do: "Save"
  defp save_button_text(type), do: type |> to_string() |> String.capitalize()

  def render_attributes(
        assigns,
        resource,
        action,
        form,
        exactly \\ nil,
        skip \\ [],
        relationship_path \\ "change"
      ) do
    ~H"""
    {{ {attributes, flags, bottom_attributes, relationship_args} = attributes(resource, action, exactly)
    nil }}
    <Context put={{ Form, form: form }}>
      <div class="grid grid-cols-6 gap-6">
        <div
          :for={{ attribute <- Enum.reject(attributes, &(&1.name in skip)) }}
          class={{
            "col-span-6",
            "sm:col-span-2": short_text?(resource, attribute),
            "sm:col-span-3": !long_text?(resource, attribute)
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
      <div class="grid grid-cols-6 gap-6" :if={{ !Enum.empty?(flags) }}>
        <div
          :for={{ attribute <- flags }}
          class={{
            "col-span-6",
            "sm:col-span-2": short_text?(resource, attribute),
            "sm:col-span-3": !long_text?(resource, attribute)
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
            "sm:col-span-2": short_text?(resource, attribute),
            "sm:col-span-3": !(long_text?(resource, attribute) || Ash.Type.embedded_type?(attribute.type))
          }}
        >
          <FieldContext name={{ attribute.name }}>
            <Label class="block text-sm font-medium text-gray-700">{{ to_name(attribute.name) }}</Label>
            {{ render_attribute_input(assigns, attribute, form) }}
            <ErrorTag field={{ attribute.name }} />
          </FieldContext>
        </div>
      </div>
      <div :for={{{relationship, argument, opts} <- relationship_args}}>
        <FieldContext name={{argument.name}} :if={{relationship not in skip and argument.name not in skip}}>
          <Label class="block text-sm font-medium text-gray-700">{{ to_name(argument.name)}}</Label>
          {{ render_relationship_input(assigns, Ash.Resource.Info.relationship(form.source.resource, relationship), form, argument.name, relationship_path <> "[#{relationship}]", opts) }}
          <ErrorTag field={{ relationship }} />
        </FieldContext>
      </div>
    </Context>
    """
  end

  defp render_relationship_input(
         assigns,
         %{cardinality: :one} = relationship,
         form,
         as,
         relationship_path,
         opts
       ) do
    ~H"""
    <div :if={{ loaded?(form.source, relationship.name) }}>
      <Inputs
        form={{ form }}
        for={{ relationship.name }}
        :let={{ form: inner_form }}
        opts={{ use_data?: true, as: form.name <> "[#{as}]" }}
      >
        <HiddenInputs for={{inner_form}} />
        <button
          type="button"
          :on-click="remove_related"
          phx-value-path={{ inner_form.name }}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          {{ {:safe, Heroicons.Solid.minus(class: "h-4 w-4 text-gray-500")} }}
        </button>
        <div class="shadow-lg p-4" :for={{{new_form, fields} <- relationship_forms(inner_form, relationship, opts, @actor) }}>
          {{ render_attributes(
            assigns,
            relationship.destination,
            new_form.source.action,
            new_form,
            fields,
            [],
            relationship_path
          ) }}
        </div>
      </Inputs>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_lookup?(opts) && !relationship_set?(form.source, relationship.name, relationship.name) }}
        phx-value-path={{ form.name <> "[#{as}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        {{ {:safe, Heroicons.Solid.search_circle(class: "h-4 w-4 text-gray-500")} }}
      </button>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_create?(opts) && !relationship_set?(form.source, relationship.name, relationship.name) }}
        phx-value-path={{ form.name <> "[#{as}]" }}
        phx-value-type={{ "create" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        {{ {:safe, Heroicons.Solid.plus(class: "h-4 w-4 text-gray-500")} }}
      </button>
    </div>
    """
  end

  defp render_relationship_input(
         assigns,
         %{cardinality: :many} = relationship,
         form,
         as,
         relationship_path,
         opts
       ) do
    ~H"""
    <div :if={{ !needs_to_load?(opts) || loaded?(form.source, relationship.name) }}>
      <Inputs
        form={{ form }}
        for={{ relationship.name }}
        :let={{ form: inner_form }}
        opts={{ use_data?: true, as: form.name <> "[#{as}]" }}
      >
        <HiddenInputs for={{inner_form}} />
        <button
          type="button"
          :on-click="remove_related"
          :if={{ relationship_set?(form.source, relationship.name, relationship.name) }}
          phx-value-path={{ inner_form.name }}
          class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          {{ {:safe, Heroicons.Solid.minus(class: "h-4 w-4 text-gray-500")} }}
        </button>
        <div class="shadow-lg p-4" :for={{{new_form, fields} <- relationship_forms(inner_form, relationship, opts, @actor) }}>
          <HiddenInput form={{inner_form}} :if={{inner_form.source.params["_lookup"] == "true"}} field="_lookup" value="true"/>
          {{ render_attributes(
            assigns,
            relationship.destination,
            new_form.source.action,
            new_form,
            fields,
            [],
            relationship_path
          ) }}
        </div>
      </Inputs>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_lookup?(opts) }}
        phx-value-path={{ form.name <> "[#{as}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        {{ {:safe, Heroicons.Solid.search_circle(class: "h-4 w-4 text-gray-500")} }}
      </button>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_create?(opts) }}
        phx-value-path={{ form.name <> "[#{as}]" }}
        phx-value-type={{ "create" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        {{ {:safe, Heroicons.Solid.plus(class: "h-4 w-4 text-gray-500")} }}
      </button>
    </div>
    <div :if={{ needs_to_load?(opts) && !loaded?(form.source, relationship.name) }}>
      <button
        :on-click="load"
        phx-value-relationship={{ relationship_path }}
        phx-value-path={{form.name <> "[#{as}]"}}
        type="button"
        class="flex py-2 ml-4 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        Load
      </button>
      <div :if={{ is_exception(@load_errors[relationship.name]) }}>
        {{ Exception.message(@load_errors[relationship.name]) }}
      </div>
      <div :if={{ @load_errors[relationship.name] && !is_exception(@load_errors[relationship.name]) }}>
        {{ inspect(@load_errors[relationship.name]) }}
      </div>
    </div>
    """
  end

  defp relationship_forms(form, relationship, opts, actor) do
    forms =
      cond do
        form.source.params["_lookup"] == "true" ->
          relationship_forms_for_lookup(form, relationship, opts, actor)

        form.source.action_type == :update ->
          relationship_forms_for_update(form, relationship, opts, actor)

        form.source.action_type == :create ->
          relationship_forms_for_create(form, relationship, opts, actor)
      end

    List.wrap(forms)
  end

  defp relationship_forms_for_lookup(form, relationship, opts, actor) do
    case opts[:on_lookup] do
      {key, create, read, fields} when relationship.type == :many_to_many ->
        query =
          relationship.destination
          |> Ash.Query.for_read(read, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        changeset =
          relationship.through
          |> Ash.Changeset.for_create(create, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{query, Ash.Resource.Info.primary_key(relationship.destination)}, {changeset, fields}] ++
          lookup_update(key, form, relationship, opts, actor)

      {key, _update, read} ->
        query =
          relationship.destination
          |> Ash.Query.for_read(read, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{query, Ash.Resource.Info.primary_key(relationship.destination)}] ++
          lookup_update(key, form, relationship, opts, actor)

      {key, create, read, fields} ->
        query =
          relationship.destination
          |> Ash.Query.for_read(read, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        changeset =
          relationship.through
          |> Ash.Changeset.for_create(create, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{query, Ash.Resource.Info.primary_key(relationship.destination)}, {changeset, fields}] ++
          lookup_update(key, form, relationship, opts, actor)
    end
  end

  defp lookup_update(:relate_and_update, form, relationship, opts, actor) do
    relationship_forms_for_update(form, relationship, opts, actor)
  end

  defp lookup_update(_, _, _, _, _), do: []

  defp relationship_forms_for_create(form, relationship, opts, actor) do
    case opts[:on_no_match] do
      {:create, action_name, join_action_name, fields} ->
        join_form =
          relationship.through
          |> Ash.Changeset.for_create(join_action_name, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        destination_form =
          relationship.destination
          |> Ash.Changeset.for_create(action_name, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{destination_form, nil}, {join_form, fields}]

      {:create, action_name} ->
        destination_form =
          relationship.destination
          |> Ash.Changeset.for_create(action_name, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{destination_form, nil}]

      :error ->
        []
    end
  end

  defp relationship_forms_for_update(form, relationship, opts, actor) do
    case opts[:on_match] do
      {:update, update, join_update, fields} ->
        join_form =
          form.source.data
          |> Ash.Changeset.for_update(update, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        destination_form =
          relationship.through.__struct__
          |> Ash.Changeset.for_update(join_update, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{destination_form, nil}, {join_form, fields}]

      {:update, action_name} ->
        destination_form =
          form.source.data
          |> Ash.Changeset.for_update(action_name, form.source.params, actor: actor)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        [{destination_form, nil}]

      {:unrelate, _action} ->
        changeset =
          form.source.data
          |> Ash.Changeset.new()
          |> Map.put(:params, form.source.params)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        {changeset, Ash.Resource.Info.primary_key(relationship.destination)}

      value when value in [:ignore, :error] ->
        changeset =
          form.source.data
          |> Ash.Changeset.new()
          |> Map.put(:params, form.source.params)
          |> Phoenix.HTML.FormData.to_form(as: form.name)

        {changeset, Ash.Resource.Info.primary_key(relationship.destination)}

      _ ->
        relationship_forms_for_create(form, relationship, opts, actor)
    end
  end

  defp needs_to_load?(opts) do
    Ash.Changeset.ManagedRelationshipHelpers.must_load?(opts)
  end

  defp loaded?(%{action_type: :create}, _), do: true

  defp loaded?(%{data: record}, relationship) do
    case Map.get(record, relationship) do
      %Ash.NotLoaded{} -> false
      _ -> true
    end
  end

  defp relationship_set?(%{action_type: :create} = changeset, relationship, id) do
    changeset.relationships
    |> Kernel.||(%{})
    |> Map.get(relationship, [])
    |> Enum.any?(fn {manage, opts} ->
      if opts[:meta][:id] == id do
        manage not in [[], nil]
      end
    end)
  end

  defp relationship_set?(changeset, relationship, id) do
    changeset.relationships
    |> Kernel.||(%{})
    |> Map.get(relationship, [])
    |> Enum.any?(fn {manage, opts} ->
      if opts[:meta][:id] == id do
        manage not in [[], nil]
      end
    end)
    |> Kernel.||(Map.get(changeset.data, relationship) not in [nil, []])
  end

  defp could_lookup?(opts) do
    Ash.Changeset.ManagedRelationshipHelpers.could_lookup?(opts)
  end

  defp could_create?(opts) do
    opts[:on_no_match] not in [:ignore, :error]
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
          default: default
        } = attribute,
        form
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID, Ash.Type.Atom] do
    cond do
      type == Ash.Type.Atom && attribute.constraints[:one_of] ->
        ~H"""
        <Select
          form={{ form }}
          field={{ name }}
          options={{ Enum.map(attribute.constraints[:one_of], &{to_name(&1), &1}) }}
        />
        """

      long_text?(form.source.resource, attribute) ->
        ~H"""
        <TextArea
          form={{ form }}
          field={{ name }}
          opts={{
            type: text_input_type(attribute),
            placeholder: placeholder(default),
            phx_hook: "MaintainAttrs",
            data_attrs: "style"
          }}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md resize-y"
        />
        """

      short_text?(form.source.resource, attribute) ->
        ~H"""
        <TextInput
          form={{ form }}
          field={{ name }}
          opts={{ type: text_input_type(attribute), placeholder: placeholder(default) }}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
        />
        """

      true ->
        ~H"""
        <TextInput
          form={{ form }}
          field={{ name }}
          opts={{ type: text_input_type(attribute), placeholder: placeholder(default) }}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
        />
        """
    end
  end

  def render_attribute_input(assigns, attribute, form) do
    if Ash.Type.embedded_type?(attribute.type) do
      ~H"""
      <Inputs form={{ form }} for={{ attribute.name }} :let={{ form: inner_form }}>
        <HiddenInputs for={{inner_form}} />
        <button
          type="button"
          :on-click="remove_embed"
          phx-value-path={{ inner_form.name }}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          {{ {:safe, Heroicons.Solid.minus(class: "h-4 w-4 text-gray-500")} }}
        </button>

        {{ render_attributes(assigns, inner_form.source.resource, inner_form.source.action, inner_form) }}
      </Inputs>
      <button
        type="button"
        :on-click="append_embed"
        phx-value-path={{ form.name <> "[#{attribute.name}]" }}
        class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        {{ {:safe, Heroicons.Solid.plus(class: "h-4 w-4 text-gray-500")} }}
      </button>
      """
    else
      ~H"""
      <TextInput
        form={{ form }}
        field={{ attribute.name }}
        opts={{ type: text_input_type(attribute), placeholder: placeholder(attribute.default) }}
        class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      />
      """
    end
  end

  defp placeholder(value) when is_function(value) do
    "DEFAULT"
  end

  defp placeholder(_), do: nil

  defp text_input_type(%{sensitive?: true}), do: "password"
  defp text_input_type(_), do: "text"

  defp redirect_to(socket, record) do
    if AshAdmin.Resource.show_action(socket.assigns.resource) do
      {:noreply,
       socket
       |> redirect(
         to:
           ash_show_path(
             socket.assigns.prefix,
             socket.assigns.api,
             socket.assigns.resource,
             record,
             socket.assigns.table
           )
       )}
    else
      case Ash.Resource.Info.primary_action(socket.assigns.resource, :update) do
        nil ->
          {:noreply,
           redirect(socket,
             to:
               ash_admin_path(socket.assigns.prefix, socket.assigns.api, socket.assigns.resource)
           )}

        update ->
          {:noreply,
           socket
           |> redirect(
             to:
               ash_update_path(
                 socket.assigns.prefix,
                 socket.assigns.api,
                 socket.assigns.resource,
                 record,
                 update,
                 socket.assigns.table
               )
           )}
      end
    end
  end

  def handle_event("change_table", %{"table" => %{"table" => table}}, socket) do
    case socket.assigns.action.type do
      :create ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_create_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.action.name,
               table
             )
         )}

      :update ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_update_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.record,
               socket.assigns.action.name,
               table
             )
         )}

      :destroy ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_destroy_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.record,
               socket.assigns.action.name,
               table
             )
         )}
    end
  end

  def handle_event("change_table", _, socket) do
    {:noreply, socket}
  end

  def handle_event("change_action", %{"action" => %{"action" => new_action}}, socket) do
    action =
      Enum.find(
        Ash.Resource.Info.actions(socket.assigns.resource),
        fn action ->
          to_string(action.name) == new_action
        end
      )

    socket = assign(socket, targets: MapSet.new())

    case action.type do
      :create ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_create_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               action.name,
               socket.assigns.table
             )
         )}

      :update ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_update_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.record,
               action.name,
               socket.assigns.table
             )
         )}

      :destroy ->
        {:noreply,
         push_redirect(socket,
           to:
             ash_destroy_path(
               socket.assigns.prefix,
               socket.assigns.api,
               socket.assigns.resource,
               socket.assigns.record,
               action.name,
               socket.assigns.table
             )
         )}
    end
  end

  def handle_event("change_action", _, socket) do
    {:noreply, socket}
  end

  def handle_event("load", %{"relationship" => relationship, "path" => path}, socket) do
    record = socket.assigns.record
    changeset = socket.assigns.changeset
    ["change" | load_path] = AshPhoenix.decode_path(relationship)
    path = AshPhoenix.decode_path(path)

    case load(record, load_path, socket) do
      {:ok, record, loaded} ->
        socket =
          cond do
            is_nil(record) || record == [] ->
              socket

            is_list(record) ->
              resource = Enum.at(record, 0).__struct__

              resource
              |> Ash.Resource.Info.primary_key()
              |> Enum.map(&to_string/1)
              |> Enum.reduce(socket, fn key, socket ->
                add_target(socket, path ++ ["~", key])
              end)

            true ->
              resource = record.__struct__

              resource
              |> Ash.Resource.Info.primary_key()
              |> Enum.map(&to_string/1)
              |> Enum.reduce(socket, fn key, socket ->
                socket
                |> add_target(path ++ ["~", key])
                |> add_target(path ++ [key])
              end)
          end

        socket = push_event(socket, "form_change", %{})
        {:noreply, assign(socket, changeset: %{changeset | data: loaded}, record: loaded)}

      {:error, _, errors} ->
        {:noreply,
         assign(socket, load_errors: Map.put(socket.assigns.load_errors, relationship, errors))}
    end
  end

  def handle_event("append_related", %{"path" => path, "type" => type}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)
      |> add_target(decoded_path ++ ["~", "_lookup"])

    # |> add_target(decoded_path ++ ["*"])

    initial =
      if type == "lookup" do
        %{"_lookup" => "true"}
      else
        %{}
      end

    {:noreply,
     socket
     |> assign(
       changeset: AshPhoenix.add_related(socket.assigns.changeset, path, "change", add: initial)
     )}
  end

  def handle_event("remove_related", %{"path" => path}, socket) do
    socket = add_target(socket, AshPhoenix.decode_path(path))
    {record, changeset} = AshPhoenix.remove_related(socket.assigns.changeset, path, "change")

    {:noreply,
     assign(socket,
       record: record,
       changeset: %{changeset | data: record}
     )}
  end

  def handle_event("append_embed", %{"path" => path}, socket) do
    {:noreply,
     assign(socket, changeset: AshPhoenix.add_embed(socket.assigns.changeset, path, "change"))}
  end

  def handle_event("remove_embed", %{"path" => path}, socket) do
    {:noreply,
     assign(socket,
       changeset: AshPhoenix.remove_embed(socket.assigns.changeset, path, "change")
     )}
  end

  def handle_event("save", data, socket) do
    params = params(data || %{}, socket)

    case socket.assigns.action.type do
      :create ->
        changeset =
          socket.assigns.resource
          |> Ash.Changeset.for_create(
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        changeset
        |> set_table(socket.assigns.table)
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
          params,
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> set_table(socket.assigns.table)
        |> socket.assigns.api.update()
        |> case do
          {:ok, updated} ->
            redirect_to(socket, updated)

          {:error, %{changeset: changeset}} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :destroy ->
        socket.assigns.record
        |> Ash.Changeset.for_destroy(
          socket.assigns.action.name,
          params,
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> set_table(socket.assigns.table)
        |> socket.assigns.api.destroy()
        |> case do
          :ok ->
            {:noreply,
             socket
             |> redirect(
               to:
                 ash_admin_path(
                   socket.assigns.prefix,
                   socket.assigns.api,
                   socket.assigns.resource
                 )
             )}

          {:error, %{changeset: changeset}} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  def handle_event("validate", data, socket) do
    socket = add_target(socket, data["_target"])
    params = params(data || %{}, socket)

    case socket.assigns.action.type do
      :create ->
        changeset =
          Ash.Changeset.for_create(
            socket.assigns.resource,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}

      :update ->
        changeset =
          Ash.Changeset.for_update(
            socket.assigns.record,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}

      :destroy ->
        changeset =
          Ash.Changeset.for_destroy(
            socket.assigns.record,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp add_target(socket, target) do
    old_targets = socket.assigns[:targets] || MapSet.new()
    assign(socket, :targets, MapSet.put(old_targets, Enum.map(target, &to_string/1)))
  end

  defp params(params, socket) do
    targets = socket.assigns[:targets] || MapSet.new()

    take_targets(params, targets)["change"]
  end

  defp load(record_or_records, [path], socket) when is_binary(path) do
    path = String.to_existing_atom(path)

    case socket.assigns.api.load(record_or_records, [path], actor: socket.assigns.actor) do
      {:ok, loaded} ->
        {:ok, Map.get(loaded, path), loaded}

      {:error, error} ->
        {:error, [path], error}
    end
  end

  defp load(records, [item | rest], socket) when is_list(records) and is_integer(item) do
    record = Enum.at(records, item)

    if record do
      case load(record, rest, socket) do
        {:ok, records, loaded} ->
          {:ok, records, List.replace_at(records, item, loaded)}

        {:error, path, error} ->
          {:error, [item | path], error}
      end
    else
      {:ok, nil, records}
    end
  end

  defp load(record, [item | rest], socket) when is_binary(item) and is_map(record) do
    key = String.to_existing_atom(item)

    case Map.get(record, key) do
      {:ok, value} ->
        case load(value, rest, socket) do
          {:ok, records, loaded} ->
            {:ok, records, Map.put(record, key, loaded)}

          {:error, path, error} ->
            {:error, [item | path], error}
        end

      :error ->
        {:ok, nil, record}
    end
  end

  defp load(value, _, _), do: {:ok, nil, value}

  defp take_targets(params, []), do: params

  defp take_targets(params, targets) when is_map(params) do
    # if Enum.any?(targets, &List.starts_with?(&1, ["*"])) do
    #   params
    # else
    Enum.reduce(params, %{}, fn {key, value}, acc ->
      case Integer.parse(key) do
        {integer, ""} ->
          case targets_for(targets, integer) do
            [] ->
              Map.put(acc, key, value)

            targets ->
              Map.put(acc, key, take_targets(value, targets))
          end

        :error ->
          if targets_for(targets, key) != [] do
            Map.put(acc, key, take_targets(value, targets_for(targets, key)))
          else
            acc
          end
      end
    end)

    # end
  end

  defp take_targets(params, _) do
    params
  end

  defp targets_for(targets, key) when is_integer(key) do
    targets
    |> Enum.filter(fn
      [first | _] ->
        first == "~" || to_string(key) == first

      _ ->
        false
    end)
    |> Enum.map(&Enum.drop(&1, 1))
  end

  defp targets_for(targets, key) do
    targets
    |> Enum.filter(&List.starts_with?(&1, [key]))
    |> Enum.map(&Enum.drop(&1, 1))
  end

  def relationships(resource, action, exactly \\ nil)

  def relationships(_resource, %{type: :read}, _), do: []

  def relationships(resource, nil, exactly) when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(&(&1.name in exactly))
  end

  def relationships(resource, :show, _) do
    resource
    |> Ash.Resource.Info.relationships()
  end

  def relationships(_resource, %{type: :destroy}, _) do
    []
  end

  def relationships(resource, action, nil) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.filter(& &1.writable?)
    |> Enum.reject(& &1.private?)
    |> only_accepted(action)
    |> sort_relationships()
  end

  defp sort_relationships(relationships) do
    [:belongs_to, :has_one, :has_many, :many_to_many]
    |> Enum.map(fn type ->
      Enum.filter(relationships, &(&1.type == type))
    end)
    |> Enum.concat()
  end

  def attributes(resource, action, exactly \\ nil)

  def attributes(resource, %{type: :read, arguments: arguments}, exactly)
      when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.map(fn attribute ->
      %{attribute | default: nil}
    end)
    |> Enum.concat(arguments)
    |> Enum.filter(&(&1.name in exactly))
    |> sort_attributes(resource)
  end

  def attributes(resource, %{type: :read, arguments: arguments}, _) do
    sort_attributes(arguments, resource)
  end

  def attributes(resource, nil, exactly) when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.filter(&(&1.name in exactly))
    |> sort_attributes(resource)
  end

  def attributes(resource, :show, _) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.reject(&(&1.name == :autogenerated_id))
    |> sort_attributes(resource)
  end

  def attributes(resource, %{type: :destroy} = action, _) do
    action.arguments
    |> Enum.reject(& &1.private?)
    |> sort_attributes(resource, action)
  end

  def attributes(resource, action, _) do
    attributes =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(& &1.writable?)
      |> Enum.reject(& &1.private?)
      |> Enum.reject(&(&1.name == :autogenerated_id))
      |> only_accepted(action)

    arguments =
      action.arguments
      |> Enum.reject(& &1.private?)

    attributes
    |> Enum.concat(arguments)
    |> sort_attributes(resource, action)
  end

  defp sort_attributes(attributes, resource, action \\ nil) do
    {relationship_args, rest} =
      attributes
      |> Enum.map(fn
        %Ash.Resource.Actions.Argument{} = argument ->
          if action do
            case manages_relationship(argument, action) do
              nil ->
                argument

              {relationship, opts} ->
                opts = opts || []
                relationship = Ash.Resource.Info.relationship(resource, relationship)

                manage_opts =
                  if opts[:type] do
                    defaults = Ash.Changeset.manage_relationship_opts(opts[:type])

                    Enum.reduce(defaults, Ash.Changeset.manage_relationship_schema(), fn {key,
                                                                                          value},
                                                                                         manage_opts ->
                      Ash.OptionsHelpers.set_default!(manage_opts, key, value)
                    end)
                  else
                    Ash.Changeset.manage_relationship_schema()
                  end

                manage_opts = Ash.OptionsHelpers.validate!(opts, manage_opts)

                opts =
                  Ash.Changeset.ManagedRelationshipHelpers.sanitize_opts(
                    relationship,
                    manage_opts
                  )

                {relationship.name, argument, opts}
            end
          else
            argument
          end

        attribute ->
          attribute
      end)
      |> Enum.split_with(&is_tuple/1)

    {flags, rest} =
      Enum.split_with(rest, fn attribute ->
        attribute.type == Ash.Type.Boolean
      end)

    {defaults, rest} =
      Enum.split_with(rest, fn attribute ->
        Ash.Type.embedded_type?(attribute.type) ||
          (not is_nil(attribute.default) && !attribute.primary_key?)
      end)

    auto_sorted =
      Enum.sort_by(rest, fn attribute ->
        {
          # Non-primary keys go to the bottom
          !Map.get(attribute, :primary_key?),
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

    sorted_defaults =
      Enum.sort_by(
        defaults,
        fn attribute ->
          {!Ash.Type.embedded_type?(attribute.type), attribute.type != Ash.Type.Boolean}
        end
      )

    {auto_sorted, flags, sorted_defaults, relationship_args}
  end

  defp manages_relationship(argument, action) do
    if action.changes do
      Enum.find_value(action.changes, fn
        %{change: {Ash.Resource.Change.ManageRelationship, opts}} ->
          if opts[:argument] == argument.name do
            {opts[:relationship], opts[:opts]}
          end

        _ ->
          false
      end)
    end
  end

  defp only_accepted(attributes, %{type: :read}), do: attributes

  defp only_accepted(attributes, %{accept: nil, reject: reject}) do
    Enum.filter(attributes, &(&1.name not in reject || []))
  end

  defp only_accepted(attributes, %{accept: accept, reject: reject}) do
    attributes
    |> Enum.filter(&(&1.name in accept))
    |> Enum.filter(&(&1.name not in reject || []))
  end

  defp actions(resource, type) do
    action_names =
      case type do
        :create ->
          AshAdmin.Resource.create_actions(resource)

        :update ->
          AshAdmin.Resource.update_actions(resource)

        :destroy ->
          AshAdmin.Resource.destroy_actions(resource)
      end

    for %{type: ^type, name: name} = action <- Ash.Resource.Info.actions(resource),
        is_nil(action_names) || name in action_names do
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
