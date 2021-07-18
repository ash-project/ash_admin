defmodule AshAdmin.Components.Resource.Form do
  @moduledoc false
  use Surface.LiveComponent

  import AshAdmin.Helpers

  require Logger

  alias Surface.Components.{Context, Form}

  alias Surface.Components.Form.{
    Checkbox,
    ErrorTag,
    FieldContext,
    Inputs,
    Label,
    Select,
    TextArea,
    TextInput
  }

  alias AshAdmin.Components.HeroIcon

  data(form, :any)
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
     |> assign_form()
     |> assign_initial_targets()
     |> assign(:initialized, true)}
  end

  defp assign_initial_targets(socket, force? \\ false) do
    if !socket.assigns[:initialized] || force? do
      socket.assigns.form.form_keys
      |> Enum.reduce(socket, fn {key, config}, socket ->
        if config[:resource] do
          if config[:type] == :list do
            config[:resource]
            |> string_pkey_fields()
            |> Enum.reduce(socket, fn pkey_field, socket ->
              add_target(socket, ["form", to_string(key), "~", pkey_field])
            end)
          else
            config[:resource]
            |> string_pkey_fields()
            |> Enum.reduce(socket, fn pkey_field, socket ->
              add_target(socket, ["form", to_string(key), pkey_field])
            end)
          end
        else
          socket
        end
      end)
    else
      socket
    end
  end

  defp string_pkey_fields(type) do
    values =
      type
      |> Ash.Resource.Info.primary_key()
      |> Enum.map(&to_string/1)

    if Enum.all?(values, &(!Ash.Resource.Info.attribute(type, &1).private?)) do
      values
    else
      ["~"]
    end
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
      <div :if={{ @form.submitted_once? }} class="ml-4 mt-4 text-red-500">
        <ul>
          <li :for={{ {field, message} <- AshPhoenix.Form.errors_for(@form, [], :simple) || [] }}>
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
          opts={{id: @id <> "_action_form"}}
        >
          <FieldContext name="action">
            <Label>Action</Label>
            <Select
              opts={{disabled: Enum.count(actions(@resource, @type)) <= 1 }}
              selected={{ to_string(@action.name) }} options={{ actions(@resource, @type) }} />
          </FieldContext>
        </Form>
      </div>
      <div class="px-4 py-5 sm:p-6">
        <Form
          for={{ @form }}
          change="validate"
          submit="save"
          opts={{ autocomplete: false, id: @id <> "_form" }}
          :let={{ form: form }}
        >
          <input hidden phx-hook="FormChange" id="resource_form">
          <input :for={{kv <- form.hidden}} name={{form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
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

  defp save_button_text(:update), do: "Save"
  defp save_button_text(type), do: type |> to_string() |> String.capitalize()

  def render_attributes(
        assigns,
        resource,
        action,
        form,
        exactly \\ nil,
        skip \\ []
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
            <ErrorTag :if={{!Ash.Type.embedded_type?(attribute.type)}} field={{ attribute.name }} />
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
            <ErrorTag :if={{!Ash.Type.embedded_type?(attribute.type)}} field={{ attribute.name }} />
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
            <ErrorTag :if={{!Ash.Type.embedded_type?(attribute.type)}} field={{ attribute.name }} />
          </FieldContext>
        </div>
      </div>
      <div :for={{{relationship, argument, opts} <- relationship_args}}>
        <FieldContext name={{argument.name}} :if={{relationship not in skip and argument.name not in skip}}>
          <Label class="block text-sm font-medium text-gray-700">{{ to_name(argument.name)}}</Label>
          {{ render_relationship_input(assigns, Ash.Resource.Info.relationship(form.source.resource, relationship), form, argument, opts) }}
        </FieldContext>
      </div>
    </Context>
    """
  end

  defp render_relationship_input(
         assigns,
         relationship,
         form,
         argument,
         opts
       ) do
    ~H"""
    <div :if={{ !needs_to_load?(opts) || loaded?(form.source.source, relationship.name) }}>
      <Inputs
        form={{ form }}
        for={{ argument.name }}
        :let={{ form: inner_form }}
      >
        <div :if={{ @form.submitted_once? }} class="ml-4 mt-4 text-red-500">
          <ul>
            <li :for={{ {field, message} <- AshPhoenix.Form.errors_for(@form, inner_form.name, :simple) || [] }}>
              <span :if={{field}}>
                {{ to_name(field) }}:
              </span>
              <span>
                {{message}}
              </span>
            </li>
          </ul>
        </div>
        <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
        {{ render_attributes(
          assigns,
          inner_form.source.resource,
          inner_form.source.source.action,
          inner_form,
          relationship_fields(inner_form),
          skip_related(relationship)
        ) }}
        <button
        type="button"
        :on-click="remove_form"
        :if={{can_remove_related?(inner_form, opts)}}
        phx-value-path={{ inner_form.name }}
        class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
      </button>
      </Inputs>

      <button
        type="button"
        :on-click="add_form"
        :if={{ can_add_related?(form, :read_action, argument)}}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="search-circle" class="h-4 w-4 text-gray-500" />
      </button>

      <button
        type="button"
        :on-click="add_form"
        :if={{ can_add_related?(form, :create_action, argument) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{"create"}}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
      </button>
      <button
        type="button"
        :on-click="add_form"
        :if={{ form.source.form_keys[argument.name][:read_form] && !relationship_set?(form.source.source, relationship.name, argument.name) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    <div :if={{ needs_to_load?(opts) && !loaded?(form.source.source, relationship.name) }}>
      <button
        :on-click="load"
        phx-value-path={{form.name}}
        phx-value-relationship={{relationship.name}}
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

  defp can_add_related?(form, action, argument) do
    if form.source.form_keys[argument.name][action] do
      case argument.type do
        {:array, _} ->
          true

        _ ->
          form.source.forms[argument.name] in [[], nil]
      end
    else
      false
    end
  end

  defp relationship_fields(inner_form) do
    if inner_form.source.type == :read do
      AshPhoenix.Form.attributes(inner_form.source)
      |> Enum.concat(AshPhoenix.Form.arguments(inner_form.source))
      |> Enum.map(& &1.name)
      |> Enum.concat(Keyword.keys(Keyword.drop(inner_form.source.form_keys, [:_join, :_update])))
      |> Enum.concat(Ash.Resource.Info.primary_key(inner_form.source.resource))
    else
      AshPhoenix.Form.attributes(inner_form.source)
      |> Enum.concat(AshPhoenix.Form.arguments(inner_form.source))
      |> Enum.map(& &1.name)
      |> Enum.concat(Keyword.keys(Keyword.drop(inner_form.source.form_keys, [:_join, :_update])))
    end
  end

  defp skip_related(relationship) do
    case relationship.type do
      :belongs_to ->
        []

      :many_to_many ->
        [relationship.source_field_on_join_table]

      _ ->
        [relationship.destination_field]
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
  end

  defp can_remove_related?(inner_form, opts) do
    if inner_form.source.type in [:create, :read] do
      true
    else
      Ash.Changeset.ManagedRelationshipHelpers.could_handle_missing?(opts)
    end
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

  def render_attribute_input(assigns, attribute, form, value \\ nil, name \\ nil)

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.Boolean,
          allow_nil?: false
        } = attribute,
        form,
        value,
        name
      ) do
    ~H"""
    <Checkbox
      form={{ form }}
      value={{value(value, form, attribute)}}
      name={{name || form.name <> "[#{attribute.name}]"}}
      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
      :props={{props(value, attribute)}}
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.Boolean
        } = attribute,
        form,
        value,
        name
      ) do
    ~H"""
    <Select
    form={{ form }}
    options={{ Nil: nil, True: "true", False: "false" }}
    selected={{boolean_selected(value(value, form, attribute))}}
    name={{name || form.name <> "[#{attribute.name}]"}}
    :props={{props(value, attribute)}} />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: type,
          default: default
        } = attribute,
        form,
        value,
        name
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID, Ash.Type.Atom] do
    cond do
      type == Ash.Type.Atom && attribute.constraints[:one_of] ->
        ~H"""
        <Select
          form={{ form }}
          :props={{props(value, attribute)}}
          options={{ Enum.map(attribute.constraints[:one_of], &{to_name(&1), &1}) ++ allow_nil_option(attribute) }}
          selected={{value(value, form, attribute)}}
          name={{name || form.name <> "[#{attribute.name}]"}}
        />
        """

      long_text?(form.source.resource, attribute) ->
        ~H"""
        <TextArea
          form={{ form }}
          :props={{props(value, attribute)}}
          name={{name || form.name <> "[#{attribute.name}]"}}
          opts={{
            type: text_input_type(attribute),
            placeholder: placeholder(default),
            phx_hook: "MaintainAttrs",
            data_attrs: "style"
          }}
          value={{value(value, form, attribute)}}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md resize-y"
        />
        """

      short_text?(form.source.resource, attribute) ->
        ~H"""
        <TextInput
          form={{ form }}
          :props={{props(value, attribute)}}
          opts={{ type: text_input_type(attribute), placeholder: placeholder(default) }}
          value={{value(value, form, attribute)}}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={{name || form.name <> "[#{attribute.name}]"}}
        />
        """

      true ->
        ~H"""
        <TextInput
          form={{ form }}
          :props={{props(value, attribute)}}
          opts={{ type: text_input_type(attribute), placeholder: placeholder(default) }}
          value={{value(value, form, attribute)}}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={{name || form.name <> "[#{attribute.name}]"}}
        />
        """
    end
  end

  def render_attribute_input(assigns, attribute, form, value, name) do
    cond do
      Ash.Type.embedded_type?(attribute.type) ->
        ~H"""
        <Inputs form={{ form }} for={{ attribute.name }} :let={{ form: inner_form }}>
          <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
          <button
            type="button"
            :on-click="remove_form"
            phx-value-path={{ inner_form.name }}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
          </button>

          {{ render_attributes(assigns, inner_form.source.resource, inner_form.source.source.action, inner_form) }}
        </Inputs>
        <button
          type="button"
          :on-click="add_form"
          :if={{can_append_embed?(form.source.source, attribute.name)}}
          phx-value-pkey={{embedded_type_pkey(attribute.type)}}
          phx-value-path={{ name || form.name <> "[#{attribute.name}]" }}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
        </button>
        """

      is_atom(attribute.type) && :erlang.function_exported(attribute.type, :values, 0) ->
        ~H"""
        <Select
          form={{ form }}
          :props={{props(value, attribute)}}
          options={{ Enum.map(attribute.type.values(), &{to_name(&1), &1}) ++ allow_nil_option(attribute) }}
          selected={{value(value, form, attribute)}}
          name={{name || form.name <> "[#{attribute.name}]"}}
        />
        """

      true ->
        render_fallback_attribute(assigns, form, attribute, value, name)
    end
  end

  defp render_fallback_attribute(assigns, form, %{type: {:array, type}} = attribute, value, name) do
    name = name || form.name <> "[#{attribute.name}]"

    ~H"""
    <div>
      <div :for.with_index={{{value, index} <- list_value(value || Phoenix.HTML.FormData.input_value(form.source, form, attribute.name))}}>
          {{render_attribute_input(assigns, %{attribute | type: type, constraints: attribute.constraints[:items] || []}, form, {:value, value}, name <> "[#{index}]")}}
          <button
            type="button"
            :on-click="remove_value"
            phx-value-path={{ form.name }}
            phx-value-field={{ attribute.name}}
            phx-value-index={{ index}}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
          <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
        </button>
      </div>
      <button
        type="button"
        :on-click="append_value"
        phx-value-path={{ form.name }}
        phx-value-field={{ attribute.name }}
        class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    """
  end

  defp render_fallback_attribute(assigns, form, attribute, value, name) do
    ~H"""
    <TextInput
      form={{ form }}
      opts={{ type: text_input_type(attribute), placeholder: placeholder(attribute.default) }}
      value={{value(value, form, attribute)}}
      name={{name || form.name <> "[#{attribute.name}]"}}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      :props={{props(value, attribute)}}
    />
    """
  end

  defp list_value(value) do
    if is_map(value) do
      value
      |> Map.to_list()
      |> Enum.sort_by(fn {key, _} -> String.to_integer(key) end)
      |> Enum.map(&elem(&1, 1))
    else
      List.wrap(value)
    end
  end

  defp embedded_type_pkey({:array, type}) do
    embedded_type_pkey(type)
  end

  defp embedded_type_pkey(type) do
    type
    |> Ash.Resource.Info.primary_key()
    |> Enum.flat_map(fn attr ->
      if Ash.Resource.Info.attribute(type, attr).private? do
        []
      else
        [attr]
      end
    end)
    |> Enum.join("-")
  end

  defp props({:value, _value}, _attribute) do
    []
  end

  defp props(_, attribute) do
    [field: attribute.name]
  end

  defp value({:value, value}, _form, _attribute), do: value

  defp value(value, form, attribute) do
    value || Phoenix.HTML.FormData.input_value(form.source, form, attribute.name)
  end

  defp allow_nil_option(%{allow_nil?: true}), do: [{"", nil}]
  defp allow_nil_option(%{default: nil}), do: [{"", nil}]
  defp allow_nil_option(_), do: []

  defp can_append_embed?(changeset, attribute) do
    case Ash.Changeset.get_attribute(changeset, attribute) do
      nil ->
        true

      value when is_list(value) ->
        true

      _ ->
        false
    end
  end

  defp boolean_selected(nil), do: :Nil
  defp boolean_selected(true), do: :True
  defp boolean_selected(false), do: :False

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

    socket = assign_initial_targets(socket, true)

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

  def handle_event("add_form", %{"path" => path} = params, socket) do
    type =
      case params["type"] do
        "lookup" -> :read
        _ -> :create
      end

    form = AshPhoenix.Form.add_form(socket.assigns.form, path, type: type)

    path =
      form
      |> AshPhoenix.Form.parse_path!(path)
      |> Enum.map(&to_string/1)

    {:noreply,
     socket
     |> assign(:form, form)
     #  |> push_event("form_change", %{})
     |> add_target(["form" | path])
     |> add_target(["form" | path] ++ ["_form_type"])}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    parsed_path = AshPhoenix.Form.parse_path!(socket.assigns.form, path)

    parsed_path =
      if is_integer(List.last(parsed_path)) do
        :lists.droplast(parsed_path)
      else
        parsed_path
      end

    parsed_path =
      parsed_path
      |> :lists.droplast()
      |> Enum.map(&to_string/1)
      |> Enum.concat(["*"])

    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)

    {:noreply,
     socket
     |> assign(:form, form)
     |> add_target(["form" | parsed_path])}
  end

  def handle_event("append_value", %{"path" => path, "field" => field}, socket) do
    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        fn adding_form ->
          new_params =
            Map.update(adding_form.params, field, %{"0" => nil}, &append_to_map(&1, nil))

          AshPhoenix.Form.validate(adding_form, new_params)
        end
      )

    path =
      form
      |> AshPhoenix.Form.parse_path!(path)
      |> Enum.map(&to_string/1)
      |> Enum.concat([field])

    {:noreply,
     socket
     |> assign(:form, form)
     |> add_target(["form" | path])}
  end

  def handle_event("load", %{"path" => path, "relationship" => relationship}, socket) do
    relationship = String.to_existing_atom(relationship)

    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        fn adding_form ->
          if adding_form.data do
            new_data = socket.assigns.api.load!(adding_form.data, relationship)
            %{adding_form | data: new_data, source: %{adding_form.source | data: new_data}}
          else
            adding_form
          end
        end
      )

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("remove_value", %{"path" => path, "field" => field, "index" => index}, socket) do
    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        fn adding_form ->
          current_value =
            adding_form.source
            |> Phoenix.HTML.FormData.input_value(nil, String.to_existing_atom(field))
            |> List.wrap()
            |> Enum.with_index()
            |> Map.new(fn {value, index} ->
              {to_string(index), value}
            end)

          new_value = Map.delete(current_value, index)

          new_value =
            if new_value == %{} do
              nil
            else
              new_value
            end

          new_params = Map.put(adding_form.params, field, new_value)

          AshPhoenix.Form.validate(adding_form, new_params)
        end
      )

    path =
      form
      |> AshPhoenix.Form.parse_path!(path)
      |> Enum.map(&to_string/1)
      |> Enum.concat([field])

    {:noreply,
     socket
     |> assign(:form, form)
     |> add_target(["form" | path])}
  end

  def handle_event("save", data, socket) do
    params = params(data || %{}, socket)

    form = AshPhoenix.Form.validate(socket.assigns.form, params || %{})

    before_submit = fn changeset ->
      changeset
      |> set_table(socket.assigns[:table])
      |> Map.put(:actor, socket.assigns[:actor])
      |> case do
        %Ash.Changeset{} ->
          Ash.Changeset.set_tenant(changeset, socket.assigns[:tenant])

        %Ash.Query{} ->
          Ash.Query.set_tenant(changeset, socket.assigns[:tenant])
      end
    end

    case AshPhoenix.Form.submit(form, socket.assigns.api, before_submit: before_submit) do
      {:ok, result} ->
        redirect_to(socket, result)

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

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def handle_event("validate", data, socket) do
    socket = add_target(socket, data["_target"])
    params = params(data || %{}, socket)

    form = AshPhoenix.Form.validate(socket.assigns.form, params || %{})

    {:noreply, assign(socket, :form, form)}
  end

  defp add_target(socket, target) do
    old_targets = socket.assigns[:targets] || MapSet.new()
    assign(socket, :targets, MapSet.put(old_targets, Enum.map(target, &to_string/1)))
  end

  defp params(params, socket) do
    targets = socket.assigns[:targets] || MapSet.new()

    take_targets(params, targets)["form"]
  end

  defp append_to_map(map, value) do
    key =
      map
      |> Map.keys()
      |> Enum.map(&String.to_integer/1)
      |> Enum.max()
      |> Kernel.||(-1)
      |> Kernel.+(1)
      |> to_string()

    Map.put(map, key, value)
  end

  defp take_targets(params, []), do: params

  defp take_targets(params, targets) when is_map(params) do
    if Enum.any?(targets, &List.starts_with?(&1, ["*"])) do
      params
    else
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
    end
  end

  defp take_targets(params, _) do
    params
  end

  defp targets_for(targets, key) when is_integer(key) do
    targets
    |> Enum.filter(fn
      [first | _] ->
        # ~ means match any key at this point
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
    |> sort_relationships()
  end

  def relationships(resource, :show, _) do
    resource
    |> Ash.Resource.Info.relationships()
    |> sort_relationships()
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
    {join_assocs, regular_assocs} =
      [:belongs_to, :has_one, :has_many, :many_to_many]
      |> Enum.map(fn type ->
        Enum.filter(relationships, &(&1.type == type))
      end)
      |> Enum.concat()
      |> Enum.split_with(&String.ends_with?(to_string(&1.name), "join_assoc"))

    regular_assocs ++ join_assocs
  end

  def attributes(resource, action, exactly \\ nil)

  def attributes(resource, :_lookup, _exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.filter(& &1.primary_key?)
    |> Enum.map(&Map.put(&1, :default, nil))
    |> sort_attributes(resource)
  end

  def attributes(resource, %{type: :read, arguments: arguments}, exactly)
      when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.map(&Map.put(&1, :default, nil))
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
          if action && map_type?(argument.type) do
            case manages_relationship(argument, action) do
              nil ->
                argument

              {relationship, opts} ->
                {relationship, argument, opts}
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
          (not is_nil(attribute.default) && !Map.get(attribute, :primary_key?))
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

  defp map_type?({:array, type}) do
    map_type?(type)
  end

  defp map_type?(:map), do: true
  defp map_type?(Ash.Type.Map), do: true

  defp map_type?(type) do
    if Ash.Type.embedded_type?(type) do
      if is_atom(type) && :erlang.function_exported(type, :admin_map_type?, 0) do
        type.admin_map_type?()
      else
        false
      end
    else
      false
    end
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

  defp assign_form(socket) do
    if socket.assigns[:initialized] do
      socket
    else
      transform_errors = fn
        _, %{class: :forbidden} ->
          {nil, "Forbidden", []}

        _, other ->
          other
      end

      form =
        if socket.assigns.action.type == :create do
          socket.assigns.resource
          |> AshPhoenix.Form.for_create(socket.assigns.action.name,
            forms: [
              auto?: true
            ],
            transform_errors: transform_errors
          )
        else
          socket.assigns.record
          |> AshPhoenix.Form.for_update(socket.assigns.action.name,
            forms: [
              auto?: true
            ],
            transform_errors: transform_errors
          )
        end

      assign(socket, :form, form)
    end
  end
end
