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
     |> assign_initial_targets()
     |> assign(:initialized, true)}
  end

  defp assign_initial_targets(socket, force? \\ false) do
    if !socket.assigns[:initialized] || force? do
      socket
      |> assign_embedded_targets()
      |> assign_relationship_targets()
    else
      socket
    end
  end

  defp assign_relationship_targets(socket) do
    socket.assigns.action.arguments
    |> Enum.flat_map(fn arg ->
      case AshPhoenix.FormData.Helpers.argument_and_manages(
             socket.assigns.changeset,
             arg.name
           ) do
        {nil, nil} ->
          []

        {argument, manages} ->
          [{argument, manages}]
      end
    end)
    |> Enum.reduce(socket, fn {argument, manages}, socket ->
      {_, opts} = manages_relationship(argument, socket.assigns.action)
      opts = sanitized_manage_opts(socket.assigns.resource, manages, opts || [])
      relationship = Ash.Resource.Info.relationship(socket.assigns.resource, manages)

      socket =
        if Ash.Changeset.ManagedRelationshipHelpers.could_update?(opts) do
          socket =
            relationship.destination
            |> string_pkey_fields()
            |> Enum.reduce(socket, fn pkey_field, socket ->
              socket
              |> add_target(["change", to_string(argument.name), "~"] ++ [pkey_field])
              |> add_target(["change", to_string(argument.name)] ++ [pkey_field])
            end)

          relationship
          |> potential_action_paths(
            opts,
            ["change"] ++ [to_string(argument.name), "~"]
          )
          |> Enum.concat(
            potential_action_paths(
              relationship,
              opts,
              ["change"] ++ [to_string(argument.name)]
            )
          )
          |> Enum.reduce(socket, fn path, socket ->
            add_target(socket, path)
          end)
        else
          socket
        end

      relationship.destination
      |> embedded_targets(["change", "~"])
      |> Enum.concat(embedded_targets(relationship.destination, ["change"]))
      |> Enum.reduce(socket, &add_target(&2, &1))
    end)
  end

  defp potential_action_paths(relationship, opts, trail) do
    relationship
    |> potential_actions(opts)
    |> Enum.flat_map(fn {resource, action} ->
      action.arguments
      |> Enum.flat_map(fn arg ->
        case manages_relationship(arg, action) do
          nil ->
            []

          {relationship, _opts} ->
            [{resource, action, arg, relationship}]
        end
      end)
      |> Enum.flat_map(fn {resource, action, argument, manages} ->
        {_, opts} = manages_relationship(argument, action)
        opts = sanitized_manage_opts(resource, manages, opts || [])
        relationship = Ash.Resource.Info.relationship(resource, manages)

        paths =
          if Ash.Changeset.ManagedRelationshipHelpers.could_update?(opts) do
            paths =
              relationship.destination
              |> string_pkey_fields()
              |> Enum.flat_map(fn pkey_field ->
                [
                  trail ++ [to_string(argument.name)] ++ [pkey_field],
                  trail ++ [to_string(argument.name)] ++ [pkey_field]
                ]
              end)

            potential_action_paths(
              relationship,
              opts,
              trail ++ [to_string(argument.name), "~"]
            ) ++
              potential_action_paths(
                relationship,
                opts,
                trail ++ [to_string(argument.name)]
              ) ++ paths
          else
            []
          end

        relationship.destination
        |> embedded_targets(trail)
        |> Enum.concat(paths)
      end)
    end)
  end

  defp potential_actions(relationship, opts) do
    all_actions =
      List.wrap(
        Ash.Changeset.ManagedRelationshipHelpers.on_lookup_update_action(opts, relationship)
      ) ++
        List.wrap(
          Ash.Changeset.ManagedRelationshipHelpers.on_match_destination_actions(
            opts,
            relationship
          )
        ) ++
        List.wrap(
          Ash.Changeset.ManagedRelationshipHelpers.on_missing_destination_actions(
            opts,
            relationship
          )
        ) ++
        List.wrap(
          Ash.Changeset.ManagedRelationshipHelpers.on_no_match_destination_actions(
            opts,
            relationship
          )
        )

    Enum.map(all_actions, fn
      {:destination, action} ->
        {relationship.destination, Ash.Resource.Info.action(relationship.destination, action)}

      {:destination, action, _} ->
        {relationship.destination, Ash.Resource.Info.action(relationship.destination, action)}

      {:source, action} ->
        {relationship.source, Ash.Resource.Info.action(relationship.source, action)}

      {:join, action, _} ->
        {relationship.through, Ash.Resource.Info.action(relationship.through, action)}
    end)
  end

  defp assign_embedded_targets(socket) do
    socket.assigns.resource
    |> Ash.Resource.Info.attributes()
    |> Enum.filter(&Ash.Type.embedded_type?(&1.type))
    |> Enum.reduce(socket, fn attribute, socket ->
      type = unwrap_type(attribute.type)
      string_pkey_fields = string_pkey_fields(type)

      socket =
        type
        |> embedded_targets()
        |> Enum.reduce(socket, &add_target(&2, ["change" | &1]))

      Enum.reduce(string_pkey_fields, socket, fn pkey_field, socket ->
        socket
        |> add_target(["change", to_string(attribute.name), "~"] ++ [pkey_field])
        |> add_target(["change", to_string(attribute.name)] ++ [pkey_field])
      end)
    end)
  end

  defp embedded_targets(embedded_resource, prefix \\ ["change"]) do
    embedded_resource
    |> Ash.Resource.Info.attributes()
    |> Enum.filter(&Ash.Type.embedded_type?(&1.type))
    |> Enum.map(fn attribute ->
      type = unwrap_type(attribute.type)
      string_pkey_fields = string_pkey_fields(type)

      targets = [
        prefix ++ [to_string(attribute.name), "~"] ++ string_pkey_fields,
        prefix ++ [to_string(attribute.name)] ++ string_pkey_fields
      ]

      targets ++ Enum.concat(Enum.map(targets, &embedded_targets(type, &1)))
    end)
    |> Enum.concat()
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

  defp unwrap_type({:array, type}), do: unwrap_type(type)
  defp unwrap_type(type), do: type

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
          as="change"
          for={{ @changeset }}
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
          {{ render_relationship_input(assigns, Ash.Resource.Info.relationship(form.source.resource, relationship), form, argument, relationship_path <> "[#{relationship}]", opts) }}
        </FieldContext>
      </div>
    </Context>
    """
  end

  defp render_relationship_input(
         assigns,
         relationship,
         form,
         %{type: {:array, _}} = argument,
         relationship_path,
         opts
       ) do
    ~H"""
    <div :if={{ !needs_to_load?(opts) || loaded?(form.source, relationship.name) }}>
      <Inputs
        form={{ form }}
        for={{ argument.name }}
        :let={{ form: inner_form }}
        opts={{ form_opts(form, opts, argument.name, relationship, @actor) }}
      >
        <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
        <button
          type="button"
          :on-click="remove_related"
          :if={{ can_remove_related?(inner_form, opts) && relationship_set?(form.source, relationship.name, argument.name) }}
          phx-value-path={{ inner_form.name }}
          class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
        </button>
        <div class="shadow-lg p-4">
          <div :for={{{inner_form, field_limit, relationship} <- relationship_forms(form, inner_form, relationship, opts, @actor)}}>
            <input name={{inner_form.name <> "[_type]"}} value={{inner_form.params["_type"] || "create"}} hidden>
            <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
            {{ render_attributes(
              assigns,
              relationship.destination,
              inner_form.source.action || :_lookup,
              maybe_clear_errors(inner_form), # We clear errors from lookup forms
              relationship_fields(inner_form, field_limit),
              skip_related(relationship, is_nil(inner_form.source.action)),
              relationship_path
            ) }}
          </div>
        </div>
      </Inputs>

      <button
        type="button"
        :on-click="append_related"
        :if={{ could_lookup?(opts) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="search-circle" class="h-4 w-4 text-gray-500" />
      </button>

      <button
        type="button"
        :on-click="append_related"
        :if={{ could_create?(opts) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{"create"}}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    <div :if={{ needs_to_load?(opts) && !loaded?(form.source, relationship.name) }}>
      <button
        :on-click="load"
        phx-value-relationship={{ relationship_path }}
        phx-value-path={{form.name <> "[#{argument.name}]"}}
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

  defp render_relationship_input(
         assigns,
         relationship,
         form,
         argument,
         relationship_path,
         opts
       ) do
    ~H"""
    <div :if={{ !(needs_to_load?(opts) && !loaded?(form.source, relationship.name)) }}>
      <Inputs
        form={{ form }}
        for={{ argument.name }}
        :let={{ form: inner_form }}
        opts={{ form_opts(form, opts, argument.name, relationship, @actor) }}
      >
        <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
        <button
          type="button"
          :on-click="remove_related"
          :if={{can_remove_related?(inner_form, opts)}}
          phx-value-path={{ inner_form.name }}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
        </button>
        <div class="shadow-lg p-4">
          <div :for={{{inner_form, type, relationship} <- relationship_forms(form, inner_form, relationship, opts, @actor)}}>
            <input :for={{kv <- inner_form.hidden}} name={{inner_form.name <> "[#{elem(kv, 0)}]"}} value={{elem(kv, 1)}} hidden>
            <input name={{inner_form.name <> "[_type]"}} value={{inner_form.params["_type"] || "create"}} hidden>
            {{ render_attributes(
              assigns,
              relationship.destination,
              inner_form.source.action || :_lookup,
              maybe_clear_errors(inner_form), # We clear errors from lookup forms
              relationship_fields(inner_form, type),
              skip_related(relationship, is_nil(inner_form.source.action)),
              relationship_path
            ) }}
          </div>
        </div>
      </Inputs>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_lookup?(opts) && !relationship_set?(form.source, relationship.name, argument.name) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{ "lookup" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="search-circle" class="h-4 w-4 text-gray-500" />
      </button>
      <button
        type="button"
        :on-click="append_related"
        :if={{ could_create?(opts) && !relationship_set?(form.source, relationship.name, argument.name) }}
        phx-value-path={{ form.name <> "[#{argument.name}]" }}
        phx-value-type={{ "create" }}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <HeroIcon name="plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    """
  end

  defp relationship_forms(form, inner_form, relationship, opts, actor) do
    cond do
      inner_form.params["_type"] == "lookup" ->
        new_inner_form =
          inner_form.source.resource
          |> Ash.Changeset.new()
          |> Map.put(:params, inner_form.params)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)
          |> Map.update!(:hidden, &Keyword.put(&1, :_type, "lookup"))

        [{new_inner_form, nil, relationship}]

      is_nil(inner_form.source.action) ->
        lookup_forms = lookup_forms(form, inner_form, opts, relationship, actor)

        case inner_form.source.action_type do
          :create ->
            lookup_forms ++
              create_forms(form, inner_form, opts, relationship, actor)

          :update ->
            if opts[:on_match] == :unrelate do
              [
                {inner_form, Ash.Resource.Info.primary_key(inner_form.source.resource),
                 relationship}
              ] ++
                lookup_forms ++
                update_forms(form, inner_form, opts, relationship, actor)
            else
              lookup_forms ++
                update_forms(form, inner_form, opts, relationship, actor)
            end

          :destroy ->
            lookup_forms ++
              destroy_forms(form, inner_form, opts, relationship, actor)
        end

      inner_form.source.action_type == :update ->
        if opts[:on_match] == :unrelate do
          [
            {inner_form, Ash.Resource.Info.primary_key(inner_form.source.resource), relationship}
          ] ++
            update_forms(form, inner_form, opts, relationship, actor)
        else
          update_forms(form, inner_form, opts, relationship, actor)
        end

      inner_form.source.action_type == :destroy ->
        destroy_forms(form, inner_form, opts, relationship, actor)

      true ->
        create_forms(form, inner_form, opts, relationship, actor)
    end
  end

  defp lookup_forms(form, inner_form, opts, relationship, actor) do
    opts
    |> Ash.Changeset.ManagedRelationshipHelpers.on_lookup_update_action(relationship)
    |> action_form(form, inner_form, relationship, actor)
    |> List.wrap()
  end

  defp update_forms(form, inner_form, opts, relationship, actor) do
    opts
    |> Ash.Changeset.ManagedRelationshipHelpers.on_match_destination_actions(relationship)
    |> Kernel.||([])
    |> Enum.map(&action_form(&1, form, inner_form, relationship, actor))
  end

  defp create_forms(form, inner_form, opts, relationship, actor) do
    opts
    |> Ash.Changeset.ManagedRelationshipHelpers.on_no_match_destination_actions(relationship)
    |> Kernel.||([])
    |> Enum.map(&action_form(&1, form, inner_form, relationship, actor))
  end

  defp destroy_forms(form, inner_form, opts, relationship, actor) do
    opts
    |> Ash.Changeset.ManagedRelationshipHelpers.on_missing_destination_actions(relationship)
    |> Enum.map(&action_form(&1, form, inner_form, relationship, actor))
  end

  # defp drop_destination_form([{:destination, _} | rest]), do: rest
  # defp drop_destination_form(other), do: other

  defp action_form(nil, _, _, _, _), do: nil

  defp action_form({:source, action_name}, form, inner_form, relationship, actor) do
    new_inner_form =
      form.source.data
      |> Ash.Changeset.for_update(action_name, inner_form.params, actor: actor)
      |> retain_hiding_errors(inner_form.source)
      |> Phoenix.HTML.FormData.to_form(as: inner_form.name)

    {new_inner_form, nil, relationship}
  end

  defp action_form({:destination, action_name}, _form, inner_form, relationship, actor) do
    new_inner_form =
      case Ash.Resource.Info.action(relationship.destination, action_name).type do
        :update ->
          inner_form.data
          |> Ash.Changeset.for_update(action_name, inner_form.params, actor: actor)
          |> retain_hiding_errors(inner_form.source)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)

        :create ->
          inner_form.data.__struct__
          |> Ash.Changeset.for_create(action_name, inner_form.params, actor: actor)
          |> retain_hiding_errors(inner_form.source)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)

        :destroy ->
          inner_form.data
          |> Ash.Changeset.for_destroy(action_name, inner_form.params, actor: actor)
          |> retain_hiding_errors(inner_form.source)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)
      end

    {new_inner_form, nil, relationship}
  end

  defp action_form({:join, action_name, keys}, form, inner_form, relationship, actor) do
    limit =
      if keys == :all do
        nil
      else
        keys
      end

    new_inner_form =
      if inner_form.source.action_type == :update do
        value = find_join(form.source.data, inner_form.source.data, relationship)

        if value do
          value
          |> Ash.Changeset.for_update(action_name, inner_form.params, actor: actor)
          |> retain_hiding_errors(inner_form.source)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)
        else
          relationship.through.__struct__
          |> Ash.Changeset.new()
          |> retain_hiding_errors(inner_form.source)
          |> Phoenix.HTML.FormData.to_form(as: inner_form.name)
        end
      else
        relationship.through
        |> Ash.Changeset.for_create(action_name, inner_form.params, actor: actor)
        |> retain_hiding_errors(inner_form.source)
        |> Phoenix.HTML.FormData.to_form(as: inner_form.name)
      end

    {new_inner_form, limit,
     Ash.Resource.Info.relationship(relationship.source, relationship.join_relationship)}
  end

  defp retain_hiding_errors(changeset, source_changeset) do
    if AshPhoenix.hiding_errors?(source_changeset) do
      AshPhoenix.hide_errors(changeset)
    else
      changeset
    end
  end

  defp find_join(source, destination, relationship) do
    case Map.get(source, relationship.join_relationship) do
      %Ash.NotLoaded{} ->
        source.__struct__.__struct__

      related ->
        related
        |> List.wrap()
        |> Enum.find(
          source.__struct__.__struct__,
          fn candidate ->
            Map.get(candidate, relationship.destination_field_on_join_table) ==
              Map.get(destination, relationship.destination_field)
          end
        )
    end
  end

  defp maybe_clear_errors(form) do
    if form.source.action do
      form
    else
      %{form | source: AshPhoenix.hide_errors(form.source), errors: []}
    end
  end

  defp relationship_fields(inner_form, limit) do
    if is_nil(inner_form.source.action) do
      Ash.Resource.Info.primary_key(inner_form.source.resource)
    else
      limit
    end
  end

  defp create_action(opts, relationship) do
    case Ash.Changeset.ManagedRelationshipHelpers.on_no_match_destination_actions(
           opts,
           relationship
         ) do
      [{:destination, action} | _rest] ->
        # do something with rest here
        action

      _ ->
        :_raw
    end
  end

  defp update_action(opts, relationship) do
    case Ash.Changeset.ManagedRelationshipHelpers.on_match_destination_actions(opts, relationship) do
      [{:destination, action} | _rest] ->
        # do something with rest here
        action

      _ ->
        :_raw
    end
  end

  defp form_opts(form, opts, as, relationship, actor) do
    [
      use_data?: use_data?(opts),
      as: form.name <> "[#{as}]",
      create_action: create_action(opts, relationship),
      update_action: update_action(opts, relationship),
      actor: actor
    ]
  end

  defp use_data?(opts) do
    Ash.Changeset.ManagedRelationshipHelpers.must_load?(opts)
  end

  defp skip_related(_, true) do
    []
  end

  defp skip_related(relationship, _) do
    if relationship.type == :belongs_to do
      []
    else
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
    if inner_form.source.action_type == :create do
      true
    else
      Ash.Changeset.ManagedRelationshipHelpers.could_handle_missing?(opts)
    end
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
            :on-click="remove_embed"
            phx-value-path={{ inner_form.name }}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
          </button>

          {{ render_attributes(assigns, inner_form.source.resource, inner_form.source.action, inner_form) }}
        </Inputs>
        <button
          type="button"
          :on-click="append_embed"
          :if={{can_append_embed?(form.source, attribute.name)}}
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
            phx-value-path={{ form.name <> "[#{attribute.name}][#{index}]" }}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
          <HeroIcon name="minus" class="h-4 w-4 text-gray-500" />
        </button>
      </div>
      <button
        type="button"
        :on-click="append_value"
        phx-value-path={{ form.name <> "[#{attribute.name}]" }}
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

  def handle_event("append_value", %{"path" => path}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)

    new_changeset = AshPhoenix.add_value(socket.assigns.changeset, path, "change")

    {:noreply,
     socket
     |> push_event("form_change", %{})
     |> assign(changeset: new_changeset)}
  end

  def handle_event("remove_value", %{"path" => path}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)

    new_changeset = AshPhoenix.remove_value(socket.assigns.changeset, path, "change")

    {:noreply,
     socket
     |> push_event("form_change", %{})
     |> assign(changeset: new_changeset)}
  end

  def handle_event("append_related", %{"path" => path, "type" => type}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)
      |> add_target(decoded_path ++ ["_type"])

    new_changeset =
      AshPhoenix.add_related(socket.assigns.changeset, path, "change", add: %{"_type" => type})

    {:noreply,
     socket
     |> push_event("form_change", %{})
     |> assign(changeset: new_changeset)}
  end

  def handle_event("remove_related", %{"path" => path}, socket) do
    socket = add_target(socket, AshPhoenix.decode_path(path))

    {record, changeset} = AshPhoenix.remove_related(socket.assigns.changeset, path, "change")

    {:noreply,
     socket
     |> assign(
       record: record,
       changeset: %{changeset | data: record}
     )}
  end

  def handle_event("append_embed", %{"path" => path, "pkey" => pkey}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)

    socket =
      if pkey do
        pkey
        |> String.split("-")
        |> Enum.reduce(socket, fn key, socket ->
          socket
          |> add_target(decoded_path ++ ["~", key])
          |> add_target(decoded_path ++ [key])
        end)
      else
        add_target(socket, decoded_path ++ ["~"])
      end

    {:noreply,
     socket
     |> assign(changeset: AshPhoenix.add_embed(socket.assigns.changeset, path, "change"))
     |> push_event("form_change", %{})}
  end

  def handle_event("remove_embed", %{"path" => path}, socket) do
    decoded_path = AshPhoenix.decode_path(path)

    socket =
      socket
      |> add_target(decoded_path)

    changeset = AshPhoenix.remove_embed(socket.assigns.changeset, path, "change")

    {:noreply,
     socket
     |> assign(changeset: changeset)}
  end

  # if socket.assigns.action.type == :update do
  #   case Ash.Resource.Info.relationship(socket.assigns.resource, Enum.at(decoded_path, 1)) do
  #     nil ->
  #       AshPhoenix.remove_embed(socket.assigns.changeset, path, "change")

  #     rel ->
  #       case Enum.at(decoded_path, 2) do
  #         index when is_integer(index) ->
  #           socket.assigns.record
  #           |> Map.get(rel.name)
  #           |> Enum.reject(&AshPhoenix.FormData.Helpers.hidden?/1)
  #           |> Enum.at(index)
  #           |> case do
  #             nil ->
  #               new_index = index - Enum.count(Map.get(socket.assigns.record, rel.name))
  #               new_decoded_path = List.replace_at(decoded_path, 2, new_index)
  #               value_to_add = AshPhoenix.add_to_path(%{}, decoded_path, nil)

  #               AshPhoenix.add_related(
  #                 socket.assigns.changeset,
  #                 new_decoded_path,
  #                 "change",
  #                 value_to_add
  #               )

  #             value ->
  #               AshPhoenix.add_()
  #           end

  #         _ ->
  #           case Map.get(socket.assigns.record, rel.name) do
  #             nil ->
  #               AshPhoenix.add_related(
  #                 socket.assigns.changeset,
  #                 path,
  #                 nil
  #               )

  #             related ->
  #               if AshPhoenix.FormData.Helpers.hidden?(related) do
  #                 AshPhoenix.add_related(
  #                   socket.assigns.changeset,
  #                   path,
  #                   nil
  #                 )
  #               else
  #                 AshPhoenix.remove_related(socket.assigns.changeset, path, "change")
  #               end
  #           end
  #       end
  #   end
  # else
  #   nil
  # end
  # |> case do
  #   {record, changeset} ->
  #     {:noreply,
  #      socket
  #      |> assign(
  #        record: record,
  #        changeset: %{changeset | data: record}
  #      )
  #      |> push_event("form_change", %{})}

  #   changeset ->
  #     {:noreply,
  #      socket
  #      |> assign(changeset: changeset)
  #      |> push_event("form_change", %{})}
  # end

  def handle_event("save", data, socket) do
    params = params(data || %{}, socket)

    case socket.assigns.action.type do
      :create ->
        changeset =
          socket.assigns.resource
          |> Ash.Changeset.for_create(
            socket.assigns.action.name,
            params || %{},
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        changeset
        |> set_table(socket.assigns.table)
        |> socket.assigns.api.create(
          authorize?: socket.assigns[:authorizing],
          actor: socket.assigns[:actor]
        )
        |> log_errors()
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
          params || %{},
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> set_table(socket.assigns.table)
        |> socket.assigns.api.update(
          authorize?: socket.assigns[:authorizing],
          actor: socket.assigns[:actor]
        )
        |> log_errors()
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
          params || %{},
          actor: socket.assigns[:actor],
          tenant: socket.assigns[:tenant]
        )
        |> set_table(socket.assigns.table)
        |> socket.assigns.api.destroy(
          authorize?: socket.assigns[:authorizing],
          actor: socket.assigns[:actor]
        )
        |> log_errors()
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

    changeset =
      case socket.assigns.action.type do
        :create ->
          Ash.Changeset.for_create(
            socket.assigns.resource,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        :update ->
          Ash.Changeset.for_update(
            socket.assigns.record,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )

        :destroy ->
          Ash.Changeset.for_destroy(
            socket.assigns.record,
            socket.assigns.action.name,
            params,
            actor: socket.assigns[:actor],
            tenant: socket.assigns[:tenant]
          )
      end

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp log_errors({:ok, _} = result), do: result
  defp log_errors(:ok), do: :ok

  defp log_errors({:error, error}) do
    Logger.warn(
      "Error while creating/updating data in ash admin: \n#{Exception.format(:error, error)}"
    )

    {:error, error}
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

    case socket.assigns.api.load(record_or_records, [path],
           actor: socket.assigns.actor,
           authorize?: socket.assigns[:authorizing]
         ) do
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
                opts = sanitized_manage_opts(resource, relationship, opts || [])

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

  defp sanitized_manage_opts(resource, relationship_name, opts) do
    relationship = Ash.Resource.Info.relationship(resource, relationship_name)

    manage_opts =
      if opts[:type] do
        defaults = Ash.Changeset.manage_relationship_opts(opts[:type])

        Enum.reduce(defaults, Ash.Changeset.manage_relationship_schema(), fn {key, value},
                                                                             manage_opts ->
          Ash.OptionsHelpers.set_default!(manage_opts, key, value)
        end)
      else
        Ash.Changeset.manage_relationship_schema()
      end

    manage_opts = Ash.OptionsHelpers.validate!(opts, manage_opts)

    Ash.Changeset.ManagedRelationshipHelpers.sanitize_opts(
      relationship,
      manage_opts
    )
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
        else
          socket.assigns.record
          |> Ash.Changeset.for_update(socket.assigns.action.name)
        end

      params =
        socket.assigns.action.arguments
        |> Enum.reduce(%{}, fn argument, params ->
          case AshPhoenix.FormData.Helpers.argument_and_manages(changeset, argument.name) do
            {nil, nil} ->
              changeset.params

            {argument, manages} ->
              relationship = Ash.Resource.Info.relationship(changeset.resource, manages)

              arg_params =
                changeset
                |> AshPhoenix.FormData.Helpers.relationship_data(
                  relationship,
                  true,
                  argument.name
                )
                |> AshPhoenix.FormData.Helpers.to_nested_form(
                  changeset,
                  relationship,
                  relationship.destination,
                  argument.name,
                  "dummy_name",
                  use_data?: true
                )
                |> List.wrap()
                |> Enum.map(& &1.params)

              Map.put(params, argument.name, arg_params)
          end
        end)

      changeset =
        if socket.assigns.action.type == :create do
          socket.assigns.resource
          |> Ash.Changeset.for_create(socket.assigns.action.name, params)
          |> AshPhoenix.hide_errors()
        else
          socket.assigns.record
          |> Ash.Changeset.for_update(socket.assigns.action.name, params)
          |> AshPhoenix.hide_errors()
        end

      assign(socket, :changeset, changeset)
    end
  end
end
