# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.Resource.Form do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.Helpers
  import AshAdmin.CoreComponents

  require Logger

  attr :resource, :any, required: true
  attr :domain, :any, required: true
  attr :record, :any, default: nil
  attr :type, :atom, default: nil
  attr :actor, :any, default: nil
  attr :tenant, :any, default: nil
  attr :authorizing, :boolean, default: false
  attr :action, :any, required: true
  attr :table, :any, required: true
  attr :tables, :any, required: true
  attr :prefix, :any, required: true
  attr :url_path, :any, required: true
  attr :params, :any, required: true
  attr :polymorphic_actions, :any, required: true

  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:load_errors, fn -> %{} end)
     |> assign_new(:loaded, fn -> %{} end)
     |> assign_new(:uploaded_files, fn -> %{} end)
     |> assign(:params, %{})}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:typeahead_options, [])
     |> assign_form()
     |> allow_uploading_form_arguments()
     |> assign(:initialized, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {render_form(assigns)}
        </div>
      </div>

      <div :if={@type != :create} class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          {AshAdmin.Components.Resource.Show.render_show(
            assigns,
            @record,
            @resource,
            "Original Record",
            false
          )}
        </div>
      </div>
    </div>
    """
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

  defp render_form(assigns) do
    ~H"""
    <div class="shadow-lg overflow-hidden sm:rounded-md bg-white">
      <div :if={@form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
        <ul>
          <li :for={{field, message} <- all_errors(@form)}>
            <span :if={field}>
              {field}:
            </span>
            <span>
              {message}
            </span>
          </li>
        </ul>
      </div>
      <h1 class="text-lg mt-2 ml-4">
        {String.capitalize(to_string(@action.type))} {AshAdmin.Resource.name(@resource)}
      </h1>
      <div class="flex justify-between col-span-6 mr-4 mt-2 overflow-auto px-4">
        <AshAdmin.Components.Resource.SelectTable.table
          resource={@resource}
          action={@action}
          on_change="change_table"
          polymorphic_actions={@polymorphic_actions}
          target={@myself}
          table={@table}
          tables={@tables}
        />
        <.form
          :let={form}
          as={:action}
          for={to_form(%{}, as: :action)}
          phx-change="change_action"
          phx-target={@myself}
          id="_action_form"
        >
          <label for="action">Action</label>
          <.input
            type="select"
            field={form[:action]}
            disabled={Enum.count(actions(@resource, @type)) <= 1}
            options={actions(@resource, @type)}
            value={to_string(@action.name)}
          />
        </.form>
      </div>
      <div class="px-4 py-5 sm:p-6">
        <.form
          :let={form}
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
          autocomplete={false}
          id="form"
        >
          <.input
            :for={kv <- form.hidden}
            name={form.name <> "[#{elem(kv, 0)}]"}
            value={elem(kv, 1)}
            type="hidden"
          />
          {render_attributes(assigns, @resource, @action, form)}
          <div class="px-4 py-3 text-right sm:px-6">
            <button
              type="submit"
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {save_button_text(@type)}
            </button>
          </div>
        </.form>
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
    assigns =
      assign(assigns,
        resource: resource,
        action: action,
        form: form,
        exactly: exactly,
        skip: skip
      )

    ~H"""
    <% {attributes, flags, bottom_attributes, relationship_args} =
      attributes(@resource, @action, @exactly) %>
    <div class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- Enum.reject(attributes, &(is_nil(@exactly) && &1.name in @skip))}
        class={
          classes([
            "col-span-6",
            "sm:col-span-full": markdown?(@resource, attribute),
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !(long_text?(@resource, attribute) || markdown?(@resource, attribute))
          ])
        }
      >
        <div>
          <label
            class="block text-sm font-medium text-gray-700"
            for={@form.name <> "[#{attribute.name}]"}
          >
            {to_name(attribute)}
          </label>
          {render_attribute_input(assigns, attribute, @form)}
          <.error_tag
            :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
            :if={!Ash.Type.embedded_type?(attribute.type)}
          >
            {replace_vars(error, vars)}
          </.error_tag>
        </div>
      </div>
    </div>
    <div :if={!Enum.empty?(flags)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div :if={!Enum.empty?(flags)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- flags}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3": !long_text?(@resource, attribute)
          ])
        }
      >
        <label
          class="block text-sm font-medium text-gray-700"
          for={@form.name <> "[#{attribute.name}]"}
        >
          {to_name(attribute.name)}
        </label>
        {render_attribute_input(assigns, attribute, @form)}
        <.error_tag
          :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
          :if={!Ash.Type.embedded_type?(attribute.type)}
        >
          {replace_vars(error, vars)}
        </.error_tag>
      </div>
    </div>
    <div :if={!Enum.empty?(bottom_attributes)} class="hidden sm:block" aria-hidden="true">
      <div class="py-5">
        <div class="border-t border-gray-200" />
      </div>
    </div>
    <div :if={!Enum.empty?(bottom_attributes)} class="grid grid-cols-6 gap-6">
      <div
        :for={attribute <- bottom_attributes}
        class={
          classes([
            "col-span-6",
            "sm:col-span-2": short_text?(@resource, attribute),
            "sm:col-span-3":
              !(long_text?(@resource, attribute) || Ash.Type.embedded_type?(attribute.type))
          ])
        }
      >
        <label
          class="block text-sm font-medium text-gray-700"
          for={@form.name <> "[#{attribute.name}]"}
        >
          {to_name(attribute.name)}
        </label>
        {render_attribute_input(assigns, attribute, @form)}
        <.error_tag
          :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
          :if={!Ash.Type.embedded_type?(attribute.type)}
        >
          {replace_vars(error, vars)}
        </.error_tag>
      </div>
    </div>
    <div :for={{relationship, argument, opts} <- relationship_args}>
      <%= if relationship not in @skip and argument.name not in @skip do %>
        <label
          class="block text-sm font-medium text-gray-700"
          for={@form.name <> "[#{argument.name}]"}
        >
          {to_name(argument.name)}
        </label>
        {render_relationship_input(
          assigns,
          Ash.Resource.Info.relationship(@form.source.resource, relationship),
          @form,
          argument,
          opts
        )}
      <% end %>
    </div>
    """
  end

  @spec error_tag(any()) :: Phoenix.LiveView.Rendered.t()
  def error_tag(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp replace_vars(string, vars) do
    vars =
      if is_map(vars) do
        vars
      else
        List.wrap(vars)
      end

    Enum.reduce(vars, string, fn {key, value}, acc ->
      if String.contains?(acc, "%{#{key}}") do
        String.replace(acc, "%{#{key}}", to_string(value))
      else
        acc
      end
    end)
  end

  defp render_relationship_input(
         assigns,
         relationship,
         form,
         argument,
         opts
       ) do
    key =
      opts[:value_is_key] ||
        relationship.destination
        |> Ash.Resource.Info.primary_key()
        |> case do
          [key] ->
            key

          _ ->
            nil
        end

    {hidden?, exactly_fields} =
      if map_type?(argument.type) || !key do
        {true, nil}
      else
        {false, [key]}
      end

    assigns =
      assign(assigns,
        relationship: relationship,
        form: form,
        argument: argument,
        opts: opts,
        key: key,
        hidden: hidden?,
        exactly_fields: exactly_fields,
        is_relationship_form: true
      )

    ~H"""
    <div :if={!must_load?(@opts) || loaded?(@form.source.source, @relationship.name)}>
      <.inputs_for :let={inner_form} field={@form[@argument.name]}>
        <div :if={@form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
          <ul>
            <li :for={{field, message} <- AshPhoenix.Form.errors(inner_form.source)}>
              <span :if={field}>
                {to_name(field)}:
              </span>
              <span>
                {message}
              </span>
            </li>
          </ul>
        </div>
        <.input
          :for={kv <- inner_form.hidden}
          :if={@hidden}
          name={inner_form.name <> "[#{elem(kv, 0)}]"}
          value={elem(kv, 1)}
          type="hidden"
        />
        <%= if inner_form.source.form_keys[:_join] do %>
          <.inputs_for :let={join_form} field={inner_form[:_join]}>
            <.input
              :for={kv <- join_form.hidden}
              :if={@hidden}
              name={inner_form.name <> "[#{elem(kv, 0)}]"}
              value={elem(kv, 1)}
              type="hidden"
            />
            {render_attributes(
              assigns,
              @relationship.through,
              join_action(@relationship.through, join_form, inner_form.source.form_keys[:_join]),
              join_form,
              @exactly_fields || inner_form.source.form_keys[:_join][:create_fields],
              skip_through_related(@exactly_fields, @relationship)
            )}
          </.inputs_for>
        <% end %>
        {render_attributes(
          assigns,
          inner_form.source.resource,
          inner_form.source.source.action,
          inner_form,
          @exactly_fields || relationship_fields(inner_form),
          skip_related(@exactly_fields, @relationship)
        )}

        <button
          :if={can_remove_related?(inner_form, @opts)}
          type="button"
          phx-click="remove_form"
          phx-target={@myself}
          phx-value-path={inner_form.name}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
        </button>
      </.inputs_for>
      <button
        :if={can_add_related?(@form, :read_action, @argument)}
        type="button"
        phx-click="add_form"
        phx-target={@myself}
        phx-value-path={@form.name <> "[#{@argument.name}]"}
        phx-value-type="lookup"
        phx-value-cardinality={to_string(@relationship.cardinality)}
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <.icon name="hero-magnifying-glass-circle" class="h-4 w-4 text-gray-500" />
      </button>

      <button
        :if={can_add_related?(@form, :create_action, @argument)}
        type="button"
        phx-click="add_form"
        phx-target={@myself}
        phx-value-path={@form.name <> "[#{@argument.name}]"}
        phx-value-type="create"
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
      </button>
      <button
        :if={
          @form.source.form_keys[@argument.name][:read_form] &&
            !relationship_set?(@form.source.source, @relationship.name, @argument.name)
        }
        type="button"
        phx-click="add_form"
        phx-target={@myself}
        phx-value-path={@form.name <> "[#{@argument.name}]"}
        phx-value-type="lookup"
        class="flex h-6 w-6 m-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    <div :if={must_load?(@opts) && !loaded?(@form.source.source, @relationship.name)}>
      <button
        phx-click="load"
        phx-target={@myself}
        phx-value-path={@form.name}
        phx-value-relationship={@relationship.name}
        type="button"
        class="flex py-2 ml-4 px-4 mt-2 bg-indigo-600 text-white border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        Load
      </button>
      <div :if={is_exception(@load_errors[@relationship.name])}>
        {Exception.message(@load_errors[@relationship.name])}
      </div>
      <div :if={@load_errors[@relationship.name] && !is_exception(@load_errors[@relationship.name])}>
        {inspect(@load_errors[@relationship.name])}
      </div>
    </div>
    """
  end

  defp join_action(through, join_form, opts) do
    name =
      case join_form.source.type do
        :create ->
          opts[:create_action]

        :update ->
          opts[:update_action]

        :destroy ->
          opts[:destroy_action]

        :read ->
          opts[:read_action]
      end

    Ash.Resource.Info.action(through, name)
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

  defp skip_related(nil, relationship) do
    case relationship.type do
      :belongs_to ->
        []

      _ ->
        [relationship.destination_attribute]
    end
  end

  defp skip_related(_, _) do
    []
  end

  defp must_load?(opts) do
    Ash.Changeset.ManagedRelationshipHelpers.must_load?(opts)
  end

  defp skip_through_related(nil, relationship) do
    [
      relationship.source_attribute_on_join_resource,
      relationship.destination_attribute_on_join_resource
    ]
  end

  defp skip_through_related(_, _) do
    []
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
        unwrap_type(attribute.type) == Ash.Type.Map
    end
  end

  defp markdown?(resource, attribute) do
    case AshAdmin.Resource.field(resource, attribute.name) do
      %{type: :markdown} ->
        true

      _ ->
        false
    end
  end

  defp unwrap_type({:array, type}), do: unwrap_type(type)
  defp unwrap_type(type), do: type

  def render_attribute_input(
        assigns,
        attribute,
        form,
        value \\ nil,
        name \\ nil,
        id \\ nil,
        union_type \\ nil
      )

  def render_attribute_input(
        assigns,
        %{type: Ash.Type.Date} = attribute,
        form,
        value,
        name,
        id,
        _
      ) do
    assigns = assign(assigns, form: form, value: value, name: name, attribute: attribute, id: id)

    ~H"""
    <.input
      type="date"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@id || @form.id <> "_#{@attribute.name}"}
    />
    """
  end

  def render_attribute_input(assigns, %{type: type} = attribute, form, value, name, id, _)
      when type in [Ash.Type.UtcDatetime, Ash.Type.UtcDatetimeUsec, Ash.Type.DateTime] do
    assigns = assign(assigns, form: form, value: value, name: name, attribute: attribute, id: id)

    ~H"""
    <.input
      type="datetime-local"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@id || @form.id <> "_#{@attribute.name}"}
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.Boolean,
          allow_nil?: false
        } = attribute,
        form,
        value,
        name,
        id,
        _
      ) do
    assigns = assign(assigns, attribute: attribute, form: form, value: value, name: name, id: id)

    ~H"""
    <.input
      type="checkbox"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@id || @form.id <> "_#{@attribute.name}"}
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
        name,
        id,
        _
      ) do
    assigns = assign(assigns, attribute: attribute, form: form, value: value, name: name, id: id)

    ~H"""
    <.input
      type="select"
      id={@id || @form.id <> "_#{@attribute.name}"}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      options={[True: "true", False: "false"]}
      value={value(@value, @form, @attribute, "true")}
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{
          type: Ash.Type.File
        } = attribute,
        form,
        value,
        name,
        id,
        _
      ) do
    upload_key = upload_key(form, attribute)

    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name,
        id: id,
        upload_key: upload_key,
        upload: assigns[:uploads][upload_key],
        uploaded_file: Map.get(assigns.uploaded_files, upload_key)
      )

    ~H"""
    <%= if @uploaded_file do %>
      <div class="flex items-center justify-between mt-2 w-full rounded-lg border border-zinc-300 text-zinc-900 text-sm overflow-hidden">
        <span class="px-2 py-2.5">{Path.basename(@uploaded_file.source)}</span>
        <button
          type="button"
          phx-click="remove_upload"
          phx-target={@myself}
          phx-value-upload-key={@upload_key}
          class="px-3 py-2.5 bg-gray-100 hover:bg-gray-200"
        >
          <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
        </button>
      </div>
    <% else %>
      <div phx-drop-target={@upload.ref}>
        <label for={@id || @upload_key} class="sr-only">Choose File</label>
        <.live_file_input
          id={@id || @upload_key}
          upload={@upload}
          class="mt-2 block w-full rounded-lg border border-zinc-300 active:border-zinc-400 text-zinc-900 text-sm file:border-0 file:text-sm file:bg-gray-200 file:me-4 file:py-2.5 file:px-4 focus:outline-none focus:border-zinc-400 target:border-zinc-400 cursor-pointer file:cursor-pointer"
        />
        <%= if length(@upload.entries) > 0 do %>
          <div class="w-full bg-gray-200 rounded-full h-1.5 mb-1 mt-1">
            <div
              class="bg-indigo-600 h-1.5 rounded-full"
              data-progress={hd(@upload.entries).progress}
              style={"width: #{hd(@upload.entries).progress}%"}
            >
            </div>
          </div>

          <p
            :for={err <- upload_errors(@upload, hd(@upload.entries))}
            class="mb-3 flex gap-3 text-sm leading-6 text-rose-600"
          >
            {error_to_string(err)}
          </p>
        <% end %>
      </div>
    <% end %>
    <p :for={err <- upload_errors(@upload)} class="alert alert-danger">
      {error_to_string(err)}
    </p>
    """
  end

  def render_attribute_input(assigns, %{type: Ash.Type.Binary}, _form, _value, _name, _id, _) do
    ~H"""
    <span class="italic">(binary fields cannot be edited)</span>
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
        name,
        id,
        _
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID, Ash.Type.Atom] do
    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        type: type,
        name: name,
        default: default,
        id: id
      )

    ~H"""
    <%= cond do %>
      <% @type == Ash.Type.Atom && @attribute.constraints[:one_of] -> %>
        <.input
          type="select"
          id={@id || @form.id <> "_#{@attribute.name}"}
          options={Enum.map(@attribute.constraints[:one_of] || [], &{to_name(&1), &1})}
          value={value(@value, @form, @attribute, default_atom_list_value(@attribute))}
          prompt={allow_nil_option(@attribute, @value)}
          name={@name || @form.name <> "[#{@attribute.name}]"}
        />
      <% markdown?(@resource, @attribute) -> %>
        <div
          phx-hook="MarkdownEditor"
          id={if @id, do: @id <> "_container", else: @form.id <> "_#{@attribute.name}_container"}
          phx-update="ignore"
          data-target-id={@form.id <> "_#{@attribute.name}"}
          class="prose max-w-none"
        >
          <textarea
            id={@id || @id || @form.id <> "_#{@attribute.name}"}
            class="prose max-w-none"
            name={@name || @form.name <> "[#{@attribute.name}]"}
          ><%= value(@value, @form, @attribute) || "" %></textarea>
        </div>
      <% long_text?(@resource, @attribute) -> %>
        <textarea
          id={@id || @form.id <> "_#{@attribute.name}"}
          name={@name || @form.name <> "[#{@attribute.name}]"}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md resize-y"
          phx-hook="MaintainAttrs"
          data-attrs="style"
          placeholder={placeholder(@default)}
        ><%= value(@value, @form, @attribute) %></textarea>
      <% short_text?(@resource, @attribute) -> %>
        <.input
          type={text_input_type(@resource, @attribute)}
          id={@id || @form.id <> "_#{@attribute.name}"}
          value={value(@value, @form, @attribute)}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={@name || @form.name <> "[#{@attribute.name}]"}
          placeholder={placeholder(@default)}
        />
      <% is_map(@attribute) and Map.has_key?(@attribute, :related_resource) && AshAdmin.Resource.label_field(@attribute.related_resource) -> %>
        <.live_component
          module={AshAdmin.Components.Resource.RelationshipField}
          id={@id || "#{@form.name}-#{@attribute.name}"}
          value={value(@value, @form, @attribute)}
          tenant={@tenant}
          actor={@actor}
          authorizing={@authorizing}
          resource={@attribute.related_resource}
          form={@form}
          attribute={@attribute}
        />
      <% true -> %>
        <.input
          type={text_input_type(@resource, @attribute)}
          placeholder={placeholder(@default)}
          id={@id || @form.id <> "_#{@attribute.name}"}
          value={value(@value, @form, @attribute)}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={@name || @form.name <> "[#{@attribute.name}]"}
        />
    <% end %>
    """
  end

  def render_attribute_input(
        assigns,
        %{type: number, default: default} = attribute,
        form,
        value,
        name,
        id,
        _
      )
      when number in [Ash.Type.Integer, Ash.Type.Float, Ash.Type.Decimal] do
    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name,
        default: default,
        id: id
      )

    ~H"""
    <.input
      type="number"
      id={@id || @form.id <> "_#{@attribute.name}"}
      value={value(@value, @form, @attribute)}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      name={@name || @form.name <> "[#{@attribute.name}]"}
      placeholder={placeholder(@default)}
    />
    """
  end

  def render_attribute_input(
        assigns,
        %{type: {:array, Ash.Type.Map}} = attribute,
        form,
        value,
        name,
        id,
        _
      ) do
    render_attribute_input(assigns, %{attribute | type: Ash.Type.Map}, form, value, name, id)
  end

  def render_attribute_input(assigns, %{type: Ash.Type.Map} = attribute, form, value, name, id, _) do
    encoded = Jason.encode!(value(value, form, attribute))

    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name,
        encoded: encoded,
        id: id
      )

    ~H"""
    <div>
      <div
        phx-hook="JsonEditor"
        phx-update="ignore"
        data-input-id={@form.id <> "_#{@attribute.name}"}
        id={if @id, do: @id <> "_json", else: @form.id <> "_#{@attribute.name}_json"}
      />

      <.input
        type="hidden"
        phx-hook="JsonEditorSource"
        data-editor-id={@form.id <> "_#{@attribute.name}_json"}
        value={@encoded}
        name={@name || @form.name <> "[#{@attribute.name}]"}
        id={@id || @form.id <> "_#{@attribute.name}"}
        class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      />
    </div>
    """
  rescue
    _ ->
      ~H"""
      <.input
        type="text"
        disabled
        value="..."
        name={@name || @form.name <> "[#{@attribute.name}]"}
        class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
      />
      """
  end

  def render_attribute_input(
        assigns,
        %{type: Ash.Type.Union} = attribute,
        form,
        value,
        name,
        id,
        _
      ) do
    union_type_name =
      if name do
        name <> "[_new_union_type]"
      else
        form.name <> "[#{attribute.name}][_new_union_type]"
      end

    actual_union_type_name =
      case value do
        {:list_value, %{params: %{"_new_union_type" => union_type}}} ->
          case Enum.find(attribute.constraints[:types], fn {type_name, _} ->
                 to_string(type_name) == union_type
               end) do
            {match, _} -> match
            _ -> elem(Enum.at(attribute.constraints[:types], 0), 0)
          end

        {:list_value, %{params: %{"_union_type" => union_type}}} ->
          case Enum.find(attribute.constraints[:types], fn {type_name, _} ->
                 to_string(type_name) == union_type
               end) do
            {match, _} -> match
            _ -> elem(Enum.at(attribute.constraints[:types], 0), 0)
          end

        {:list_value,
         %AshPhoenix.Form{
           resource: AshPhoenix.Form.WrappedValue,
           data: %{value: %Ash.Union{type: type}}
         }} ->
          type

        _ ->
          with %Phoenix.HTML.FormField{value: [%Phoenix.HTML.Form{} = attr_form]} <-
                 form[attribute.name],
               union_type <- non_nil_form_field(attr_form, [:_new_union_type, :_union_type]),
               {match, _} <-
                 Enum.find(attribute.constraints[:types], fn {type_name, _} ->
                   to_string(type_name) == to_string(union_type)
                 end) do
            match
          else
            _ ->
              elem(Enum.at(attribute.constraints[:types], 0), 0)
          end
      end

    actual_union_type =
      Keyword.get(attribute.constraints[:types], actual_union_type_name)[:type] || Ash.Type.String

    actual_union_constraints =
      Keyword.get(attribute.constraints[:types], actual_union_type_name)[:constraints] || []

    {name, id} =
      if Ash.Type.embedded_type?(actual_union_type) do
        {name, id}
      else
        name =
          if name do
            name <> "[value]"
          else
            form.name <> "[#{attribute.name}][value]"
          end

        id =
          if id do
            id <> "_value"
          else
            form.id <> "_#{attribute.name}_value"
          end

        {name, id}
      end

    union_type_id = "#{id}_#{attribute.name}_union_type"

    assigns =
      assign(
        assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name,
        id: id,
        union_type_id: union_type_id,
        possible_types: Keyword.keys(attribute.constraints[:types]),
        actual_union_type: actual_union_type,
        actual_union_constraints: actual_union_constraints,
        union_type_name: union_type_name,
        actual_union_type_name: actual_union_type_name,
        actual_union_value: value(value, form, attribute, attribute.default)
      )

    ~H"""
    <div class={if !is_nil(@actual_union_value), do: "border", else: ""}>
      <label
        :if={!is_nil(@actual_union_value)}
        class="block text-sm font-medium text-gray-700"
        for={@union_type_name}
      >
        Type
      </label>
      <div class="w-full">
        <.input
          :if={not (is_nil(@actual_union_value) && map_type?(@actual_union_type))}
          phx-change="union-type-changed"
          id={@union_type_id}
          name={@union_type_name}
          type="select"
          value={@actual_union_type_name}
          options={@possible_types}
          field={@form[:_union_type]}
        />
        {render_attribute_input(
          assigns,
          %{@attribute | type: @actual_union_type, constraints: @actual_union_constraints},
          @form,
          @actual_union_value,
          @name,
          @id,
          @actual_union_type_name
        )}
      </div>
    </div>
    """
  end

  def render_attribute_input(assigns, attribute, form, value, name, id, union_type) do
    if Ash.Type.NewType.new_type?(attribute.type) do
      constraints = Ash.Type.NewType.constraints(attribute.type, attribute.constraints)
      type = Ash.Type.NewType.subtype_of(attribute.type)
      attribute = %{attribute | type: type, constraints: constraints}
      render_attribute_input(assigns, attribute, form, value, name, id)
    else
      assigns =
        assign(assigns,
          attribute: attribute,
          form: form,
          value: value,
          name: name,
          union_type: union_type,
          id: id
        )

      ~H"""
      <%= cond do %>
        <% match?({:array, {:array, _}}, @attribute.type) -> %>
          {render_fallback_attribute(assigns, @form, @attribute, @value, @name, @id, @union_type)}
        <% match?({:array, _}, @attribute.type) && Ash.Type.embedded_type?(@attribute.type) -> %>
          <.inputs_for :let={inner_form} field={@form[@attribute.name]}>
            <.input
              :for={kv <- inner_form.hidden}
              name={inner_form.name <> "[#{elem(kv, 0)}]"}
              value={elem(kv, 1)}
              type="hidden"
            />
            <button
              type="button"
              phx-click="remove_form"
              phx-target={@myself}
              phx-value-path={inner_form.name}
              class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
            >
              <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
            </button>

            {render_attributes(
              assigns,
              inner_form.source.resource,
              inner_form.source.source.action,
              %{
                inner_form
                | id: nested_form_id(@id, @form.id, @attribute.name, inner_form),
                  name: nested_form_name(@name, @form.name, @attribute.name, inner_form)
              }
            )}
          </.inputs_for>
          <button
            :if={can_append_embed?(@form.source, @attribute.name, @attribute.type)}
            type="button"
            phx-click="add_form"
            phx-target={@myself}
            phx-value-pkey={embedded_type_pkey(@attribute.type)}
            phx-value-union-type={@union_type}
            phx-value-path={@form.name <> "[#{@attribute.name}]"}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
          </button>
        <% Ash.Type.embedded_type?(@attribute.type) && match?([%AshPhoenix.Form{} | _], @value) -> %>
          <%= for inner_form <- Enum.map(@value, &to_form/1) do %>
            <.input
              :for={kv <- inner_form.hidden}
              name={inner_form.name <> "[#{elem(kv, 0)}]"}
              value={elem(kv, 1)}
              type="hidden"
            />
            <button
              type="button"
              phx-click="remove_form"
              phx-target={@myself}
              phx-value-path={inner_form.name}
              class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
            >
              <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
            </button>

            {render_attributes(
              assigns,
              inner_form.source.resource,
              inner_form.source.source.action,
              %{
                inner_form
                | id: @id || @form.id <> "_#{@attribute.name}",
                  name: @name || @form.name <> "[#{@attribute.name}]"
              }
            )}
          <% end %>
          <button
            :if={can_append_embed?(@form.source, @attribute.name, @attribute.type)}
            type="button"
            phx-click="add_form"
            phx-target={@myself}
            phx-value-union-type={@union_type}
            phx-value-pkey={embedded_type_pkey(@attribute.type)}
            phx-value-path={@form.name <> "[#{@attribute.name}]"}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
          </button>
        <% Ash.Type.embedded_type?(@attribute.type) && match?(%AshPhoenix.Form{}, @value) -> %>
          <% inner_form = to_form(@value) %>
          <.input
            :for={kv <- inner_form.hidden}
            name={inner_form.name <> "[#{elem(kv, 0)}]"}
            value={elem(kv, 1)}
            type="hidden"
          />

          <button
            type="button"
            phx-click="remove_form"
            phx-target={@myself}
            phx-value-path={inner_form.name}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
          </button>
          {render_attributes(
            assigns,
            inner_form.source.resource,
            inner_form.source.source.action,
            %{
              inner_form
              | id: @id || @form.id <> "_#{@attribute.name}",
                name: @name || @form.name <> "[#{@attribute.name}]"
            }
          )}
        <% Ash.Type.embedded_type?(@attribute.type) && match?(%{source: %AshPhoenix.FilterForm.Arguments{}}, @form) -> %>
          {"AshPhoenix.FilterForm doesn't support embedded yet"}
        <% Ash.Type.embedded_type?(@attribute.type) -> %>
          <.inputs_for :let={inner_form} field={@form[@attribute.name]}>
            <.input
              :for={kv <- inner_form.hidden}
              name={inner_form.name <> "[#{elem(kv, 0)}]"}
              value={elem(kv, 1)}
              type="hidden"
            />
            <button
              type="button"
              phx-click="remove_form"
              phx-target={@myself}
              phx-value-path={inner_form.name}
              class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
            >
              <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
            </button>

            {render_attributes(
              assigns,
              inner_form.source.resource,
              inner_form.source.source.action,
              %{
                inner_form
                | id: @id || @form.id <> "_#{@attribute.name}",
                  name: @name || @form.name <> "[#{@attribute.name}]"
              }
            )}
          </.inputs_for>
          <button
            :if={can_append_embed?(@form.source, @attribute.name, @attribute.type)}
            type="button"
            phx-click="add_form"
            phx-target={@myself}
            phx-value-union-type={@union_type}
            phx-value-pkey={embedded_type_pkey(@attribute.type)}
            phx-value-path={@form.name <> "[#{@attribute.name}]"}
            class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
          >
            <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
          </button>
        <% is_atom(@attribute.type) && function_exported?(@attribute.type, :values, 0) -> %>
          <.input
            type="select"
            id={@form.id <> "_#{@attribute.name}"}
            options={Enum.map(@attribute.type.values(), &{to_name(&1), &1})}
            value={value(@value, @form, @attribute, List.first(@attribute.type.values()))}
            prompt={allow_nil_option(@attribute, @value)}
            name={@name || @form.name <> "[#{@attribute.name}]"}
          />
        <% true -> %>
          {render_fallback_attribute(assigns, @form, @attribute, @value, @name, @id, @union_type)}
      <% end %>
      """
    end
  end

  defp nested_form_id(id, form_id, attribute_name, inner_form) do
    if id do
      "#{id}_#{inner_form.index}"
    else
      "#{form_id}_#{attribute_name}_#{inner_form.index}"
    end
  end

  defp nested_form_name(name, form_name, attribute_name, inner_form) do
    if name do
      "#{name}[#{inner_form.index}]"
    else
      "#{form_name}[#{attribute_name}][#{inner_form.index}]"
    end
  end

  defp render_fallback_attribute(
         assigns,
         form,
         %{type: {:array, type}} = attribute,
         value,
         name,
         id,
         union_type
       ) do
    name = name || form.name <> "[#{attribute.name}]"
    id = id || form.id <> "_#{attribute.name}"

    assigns =
      assign(assigns,
        form: form,
        attribute: attribute,
        type: type,
        value: value,
        name: name,
        id: id,
        union_type: union_type || default_union_type(type, attribute.constraints[:items] || [])
      )

    ~H"""
    <div>
      <div :for={
        {this_value, index} <-
          Enum.with_index(list_value(@value || value(@value, @form, @attribute)))
      }>
        {render_attribute_input(
          assigns,
          %{@attribute | type: @type, constraints: @attribute.constraints[:items] || []},
          @form,
          {:list_value, this_value},
          @name <> "[#{index}]",
          @id <> "_#{index}",
          @union_type
        )}
        <button
          type="button"
          phx-click="remove_value"
          phx-target={@myself}
          phx-value-path={@form.name}
          phx-value-field={@attribute.name}
          phx-value-index={index}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <.icon name="hero-minus" class="h-4 w-4 text-gray-500" />
        </button>
      </div>
      <button
        type="button"
        phx-click="append_value"
        phx-target={@myself}
        phx-value-path={@form.name}
        phx-value-field={@attribute.name}
        phx-value-union-type={@union_type}
        class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    """
  end

  defp render_fallback_attribute(assigns, form, attribute, value, name, id, _union_type) do
    assigns =
      assign(assigns,
        form: form,
        attribute: attribute,
        value: value,
        name: name,
        id: id
      )

    ~H"""
    <.input
      type={text_input_type(@form.source.resource, @attribute)}
      placeholder={placeholder(@attribute.default)}
      value={value(@value, @form, @attribute, @attribute.default)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@id || @form.id <> "_#{@attribute.name}"}
      class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    />
    """
  rescue
    _ ->
      case Map.fetch(form.params, to_string(attribute.name)) do
        {:ok, value} ->
          assigns = assign(assigns, value: value)

          ~H"""
          <.input
            type={text_input_type(@form.source.resource, @attribute)}
            placeholder={placeholder(@attribute.default)}
            value={value(@value, @form, @attribute, @attribute.default)}
            name={@name || @form.name <> "[#{@attribute.name}]"}
            id={@id || @form.id <> "_#{@attribute.name}"}
            class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          />
          """

        :error ->
          ~H"""
          <.input
            type="text"
            disabled
            value="..."
            name={@name || @form.name <> "[#{@attribute.name}]"}
            id={@id || @form.id <> "_#{@attribute.name}"}
            class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          />
          """
      end
  end

  defp default_union_type(Ash.Type.Union, constraints) do
    constraints[:types]
    |> List.wrap()
    |> Enum.at(0)
    |> elem(0)
    |> to_string()
  end

  defp default_union_type(_, _), do: nil

  defp non_nil_form_field(_form, []), do: nil

  defp non_nil_form_field(form, [field | rest]) do
    case form[field] do
      %Phoenix.HTML.FormField{form: %{data: %{value: %Ash.Union{type: type}}}} ->
        type

      %Phoenix.HTML.FormField{value: value} when not is_nil(value) ->
        value

      _ ->
        non_nil_form_field(form, rest)
    end
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
      if Ash.Resource.Info.attribute(type, attr).public? do
        [attr]
      else
        []
      end
    end)
    |> Enum.join("-")
  end

  defp value(value, form, attribute, default \\ nil) do
    case do_value(value, form, attribute, default) do
      %AshPhoenix.Form{resource: AshPhoenix.Form.WrappedValue} = form ->
        form
        |> AshPhoenix.Form.value(:value)
        |> Phoenix.HTML.Safe.to_iodata()

      value ->
        value
    end
  end

  defp do_value({:list_value, %Ash.Union{value: value}}, _, _, _), do: value
  defp do_value({:list_value, value}, _, _, _), do: value

  defp do_value(%Ash.Union{value: value}, _form, _attribute, _) when not is_nil(value), do: value
  defp do_value(value, _form, _attribute, _) when not is_nil(value), do: value

  defp do_value(
         _value,
         %{source: %AshPhoenix.FilterForm.Arguments{} = arguments},
         %{name: attribute_name},
         _default
       ) do
    with :error <- Map.fetch(arguments.params, to_string(attribute_name)),
         :error <- Map.fetch(arguments.input, attribute_name) do
      nil
    else
      {:ok, v} -> v
    end
  end

  defp do_value(_value, %{source: form}, attribute, _default) do
    case AshPhoenix.Form.value(form, attribute.name) do
      %Ash.Union{value: value} -> value
      value -> value
    end
  end

  defp default_atom_list_value(%{allow_nil?: false, constraints: [one_of: [atom | _]]}), do: atom
  defp default_atom_list_value(%{default: default}), do: default
  defp default_atom_list_value(%{constraints: [one_of: [atom | _]]}), do: atom
  defp default_atom_list_value(_), do: nil

  defp allow_nil_option(_, {:list_value, _}), do: "-"
  defp allow_nil_option(%{allow_nil?: true}, _), do: "-"

  defp allow_nil_option(_, _), do: "Select an option"

  defp can_append_embed?(form, attribute, _) do
    case AshPhoenix.Form.value(form, attribute) do
      %Ash.Union{value: nil} ->
        true

      nil ->
        true

      value when is_list(value) ->
        true

      _ ->
        false
    end
  end

  defp placeholder(value) when is_function(value) do
    "DEFAULT"
  end

  defp placeholder(_), do: nil

  defp text_input_type(resource, %{name: name, sensitive?: true}) do
    show_sensitive_fields = AshAdmin.Resource.show_sensitive_fields(resource)

    if Enum.member?(show_sensitive_fields, name) do
      "text"
    else
      "password"
    end
  end

  defp text_input_type(_, _), do: "text"

  defp redirect_to(socket, record) do
    if AshAdmin.Resource.show_action(socket.assigns.resource) do
      {:noreply,
       socket
       |> redirect(
         to:
           "#{socket.assigns.prefix || "/"}?domain=#{AshAdmin.Domain.name(socket.assigns.domain)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}&table=#{socket.assigns.table}&primary_key=#{encode_primary_key(record)}&action_type=read"
       )}
    else
      case AshAdmin.Helpers.primary_action(socket.assigns.resource, :update) do
        nil ->
          {:noreply,
           redirect(socket,
             to:
               "#{socket.assigns.prefix || "/"}?domain=#{AshAdmin.Domain.name(socket.assigns.domain)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}"
           )}

        _update ->
          {:noreply,
           socket
           |> redirect(
             to:
               "#{socket.assigns.prefix || "/"}?domain=#{AshAdmin.Domain.name(socket.assigns.domain)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}&action_type=update&table=#{socket.assigns.table}&primary_key=#{encode_primary_key(record)}"
           )}
      end
    end
  end

  def handle_event("union-type-changed", %{"_target" => path} = params, socket) do
    new_type = get_in(params, path)
    # The last part of the path in this case is the field name
    path =
      socket.assigns.form
      |> AshPhoenix.Form.parse_path!(:lists.droplast(path))

    new_union_types = (socket.assigns[:union_types] || %{}) |> Map.put(path, new_type)

    if AshPhoenix.Form.has_form?(socket.assigns.form, path) do
      nested_form = AshPhoenix.Form.get_form(socket.assigns.form, path)

      form =
        socket.assigns.form
        |> AshPhoenix.Form.remove_form(path)
        |> AshPhoenix.Form.add_form(path,
          params: %{"_new_union_type" => new_type, "_union_type" => new_type},
          type: nested_form.type
        )

      {:noreply, assign(socket, form: form, union_types: new_union_types)}
    else
      {:noreply, assign(socket, union_types: new_union_types)}
    end
  end

  def handle_event("change_table", %{"table" => %{"table" => table}}, socket) do
    case socket.assigns.action.type do
      :create ->
        {:noreply,
         push_patch(socket,
           to: self_path(socket.assigns.url_path, socket.assigns.params, %{"table" => table})
         )}

      :update ->
        {:noreply,
         push_patch(socket,
           to: self_path(socket.assigns.url_path, socket.assigns.params, %{"table" => table})
         )}

      :destroy ->
        {:noreply,
         push_patch(socket,
           to: self_path(socket.assigns.url_path, socket.assigns.params, %{"table" => table})
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

    {:noreply,
     push_patch(socket,
       to: self_path(socket.assigns.url_path, socket.assigns.params, %{"action" => action.name}),
       replace: true
     )}
  end

  def handle_event("change_action", _, socket) do
    {:noreply, socket}
  end

  def handle_event("add_form", %{"path" => path} = params, socket) do
    AshPhoenix.Form.params(socket.assigns.form)

    type =
      case params["type"] do
        "lookup" -> :read
        _ -> :create
      end

    params =
      if params["union-type"] && params["union-type"] != "" do
        path = AshPhoenix.Form.parse_path!(socket.assigns.form, path)
        %{"_union_type" => socket.assigns[:union_types][path] || params["union-type"]}
      else
        %{}
      end

    form = AshPhoenix.Form.add_form(socket.assigns.form, path, type: type, params: params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> allow_uploading_form_arguments()}
  end

  def handle_event("remove_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form, path)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("append_value", %{"path" => path, "field" => field} = params, socket) do
    to_append =
      case params["union-type"] do
        nil -> nil
        value when value not in ["", nil] -> %{"_union_type" => value}
        _ -> nil
      end

    list =
      AshPhoenix.Form.get_form(socket.assigns.form, path)
      |> AshPhoenix.Form.value(String.to_existing_atom(field))
      |> List.wrap()
      |> Enum.map(fn
        %AshPhoenix.Form{} = form ->
          AshPhoenix.Form.params(form)

        other ->
          other
      end)
      |> append_to_and_map(to_append)

    params =
      put_in_creating(
        socket.assigns.form.source.raw_params || %{},
        Enum.map(AshPhoenix.Form.parse_path!(socket.assigns.form, path) ++ [field], &to_string/1),
        list
      )

    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("load", %{"path" => path, "relationship" => relationship}, socket) do
    relationship = String.to_existing_atom(relationship)

    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        fn adding_form ->
          if adding_form.data do
            new_data =
              Ash.load!(adding_form.data, relationship,
                actor: socket.assigns.actor,
                tenant: socket.assigns.tenant,
                domain: socket.assigns.domain
              )

            updated_form =
              adding_form
              |> Map.put(:data, new_data)
              |> AshPhoenix.Form.validate(adding_form.raw_params, errors: false)
              |> AshPhoenix.Form.update_options(fn opts ->
                Keyword.update(opts, :forms, [], fn forms ->
                  Keyword.new(forms, fn {key, val} ->
                    if val[:managed_relationship] == {adding_form.resource, relationship} do
                      new_data =
                        case val[:type] do
                          :single -> Enum.at(List.wrap(Map.get(new_data, relationship)), 0)
                          _ -> new_data
                        end

                      {key, Keyword.put(val, :data, new_data)}
                    else
                      {key, val}
                    end
                  end)
                end)
              end)

            if Map.has_key?(adding_form.source, :data) do
              %{updated_form | data: new_data, source: %{adding_form.source | data: new_data}}
            else
              updated_form
            end
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
        &remove_value(&1, field, index)
      )

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  def handle_event("save", %{"form" => form_params}, socket) do
    form = socket.assigns.form

    before_submit = fn changeset ->
      changeset
      |> set_table(socket.assigns[:table])
      |> Map.put(:actor, socket.assigns[:actor])
    end

    socket = consume_file_uploads(socket)

    params =
      form_params
      |> replace_new_union_stubs()
      |> replace_unused()
      |> add_file_uploads(socket.assigns.uploaded_files)

    case AshPhoenix.Form.submit(form,
           before_submit: before_submit,
           force?: true,
           params: params
         ) do
      {:ok, result} ->
        redirect_to(socket, result)

      :ok ->
        {:noreply,
         socket
         |> redirect(
           to:
             "#{socket.assigns.prefix}?domain=#{AshAdmin.Domain.name(socket.assigns.domain)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}"
         )}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def handle_event("remove_upload", %{"upload-key" => upload_key}, socket) do
    {:noreply,
     update(socket, :uploaded_files, fn uploaded_files ->
       Map.delete(uploaded_files, upload_key)
     end)}
  end

  def handle_event("validate", %{"form" => params} = event, socket) do
    params =
      params
      |> replace_new_union_stubs()
      |> replace_unused()

    form =
      AshPhoenix.Form.validate(socket.assigns.form, params,
        only_touched?: true,
        target: event["_target"] || []
      )

    {:noreply, assign(socket, form: form)}
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp consume_file_uploads(socket) do
    uploaded_files =
      socket.assigns[:uploads]
      |> case do
        nil -> %{}
        uploads -> uploads
      end
      |> Enum.filter(fn {_, upload_config} ->
        is_struct(upload_config, Phoenix.LiveView.UploadConfig)
      end)
      |> Enum.flat_map(fn {name, _} ->
        consume_uploaded_entries(socket, name, fn %{path: path}, entry ->
          random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

          tmp_dir = Path.join([System.tmp_dir!(), random_string])
          tmp_file = Path.join([tmp_dir, entry.client_name])

          File.mkdir_p!(tmp_dir)
          File.cp!(path, tmp_file)

          {:ok, {entry.upload_config, Ash.Type.File.from_path(tmp_file)}}
        end)
      end)
      |> Enum.into(%{})

    update(socket, :uploaded_files, fn existing_files ->
      Map.merge(existing_files, uploaded_files)
    end)
  end

  defp add_file_uploads(form_params, uploaded_files) do
    Enum.reduce(uploaded_files, form_params, fn {param_path, file}, params ->
      update_params_with_path(params, param_path, file)
    end)
  end

  defp update_params_with_path(params, path, value) do
    path = String.trim_leading(path, "form")

    path =
      path
      |> String.replace("[", "")
      |> String.split("]")
      |> Enum.reject(&(&1 == ""))

    put_in(params, Enum.map(path, &Access.key(&1, %{})), value)
  end

  defp replace_new_union_stubs(value) when is_list(value) do
    Enum.flat_map(value, fn value ->
      if new_union_stub?(value) do
        []
      else
        [replace_new_union_stubs(value)]
      end
    end)
  end

  defp replace_new_union_stubs(params) when is_map(params) and not is_struct(params) do
    params =
      if Map.has_key?(params, "_new_union_type") and not Map.has_key?(params, "_union_type") do
        params
        |> Map.delete("_new_union_type")
        |> Map.put("_union_type", params["_new_union_type"])
      else
        params
      end

    Enum.reduce(params, %{}, fn {key, value}, acc ->
      if new_union_stub?(value) do
        acc
      else
        Map.put(acc, key, replace_new_union_stubs(value))
      end
    end)
  end

  defp replace_new_union_stubs(value) do
    value
  end

  defp replace_unused(params) when is_map(params) do
    Map.to_list(params)
    |> replace_unused()
    |> Map.new()
  end

  defp replace_unused(params) when is_list(params) do
    params
    |> Enum.map(&replace_unused/1)
    |> Enum.reject(&is_nil(&1))
  end

  defp replace_unused({"_unused_" <> _attr, _value}), do: nil

  defp replace_unused({attribute, value}) when is_map(value),
    do: {attribute, replace_unused(value)}

  defp replace_unused({attribute, value}), do: {attribute, value}

  defp replace_unused(value), do: value

  defp new_union_stub?(value) do
    is_map(value) and Map.has_key?(value, "_new_union_type") and map_size(value) == 1
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
          |> Enum.map(fn
            %AshPhoenix.Form{} = form ->
              AshPhoenix.Form.params(form)

            other ->
              other
          end)
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

    new_params = Map.put(form.raw_params, field, new_value)

    AshPhoenix.Form.validate(form, new_params)
  end

  defp append_to_and_map(list, value) do
    list
    |> Enum.concat([value])
    |> Enum.with_index()
    |> Map.new(fn {v, i} ->
      {"#{i}", v}
    end)
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

  def relationships(_resource, _action, _) do
    []
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

  def attributes(resource, %Ash.Resource.Calculation{arguments: arguments}, _exacly) do
    sort_attributes(arguments, resource)
    |> relate_attributes(resource)
  end

  def attributes(resource, %{type: :read, arguments: arguments}, exactly)
      when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.map(&Map.put(&1, :default, nil))
    |> Enum.concat(arguments)
    |> Enum.filter(&(&1.name in exactly))
    |> sort_attributes(resource)
    |> relate_attributes(resource)
  end

  def attributes(resource, %{type: :read, arguments: arguments}, _) do
    sort_attributes(arguments, resource)
    |> relate_attributes(resource)
  end

  def attributes(resource, nil, exactly) when not is_nil(exactly) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.filter(&(&1.name in exactly))
    |> sort_attributes(resource)
    |> relate_attributes(resource)
  end

  def attributes(resource, :show, _) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.reject(&(&1.name == :autogenerated_id))
    |> sort_attributes(resource)
    |> relate_attributes(resource)
  end

  def attributes(resource, %{type: :destroy} = action, _) do
    action.arguments
    |> Enum.filter(& &1.public?)
    |> sort_attributes(resource, action)
    |> relate_attributes(resource)
  end

  def attributes(resource, action, _) do
    arguments =
      action.arguments
      |> Enum.filter(& &1.public?)

    attributes =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(& &1.writable?)
      |> Enum.reject(&(&1.name == :autogenerated_id))
      |> only_accepted(action)
      |> Enum.reject(fn attribute ->
        Enum.any?(arguments, &(&1.name == attribute.name))
      end)

    attributes
    |> Enum.concat(arguments)
    |> sort_attributes(resource, action)
    |> relate_attributes(resource)
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

  defp relate_attributes({auto_sorted, flags, sorted_defaults, relationship_args}, resource) do
    auto_sorted_with_relationships =
      Enum.map(auto_sorted, fn
        %Ash.Resource.Attribute{} = attribute ->
          relationships = Ash.Resource.Info.relationships(resource)

          if attribute.primary_key? do
            case Enum.find(relationships, fn
                   %Ash.Resource.Relationships.BelongsTo{destination_attribute: dest_attr} ->
                     dest_attr == attribute.name

                   _other ->
                     false
                 end) do
              %{source: source} -> Map.put(attribute, :related_resource, source)
              _ -> attribute
            end
          else
            case Enum.find(relationships, fn
                   %Ash.Resource.Relationships.BelongsTo{source_attribute: src_attr} ->
                     src_attr == attribute.name

                   _other ->
                     false
                 end) do
              %{destination: destination} -> Map.put(attribute, :related_resource, destination)
              _ -> attribute
            end
          end

        attribute ->
          attribute
      end)

    {auto_sorted_with_relationships, flags, sorted_defaults, relationship_args}
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
    if Map.get(action, :changes) do
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
  defp only_accepted(_, %{type: :action}), do: []

  defp only_accepted(attributes, %{accept: accept}) do
    Enum.filter(attributes, &(&1.name in accept))
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

    Enum.map(action_names, &{to_name(&1), to_string(&1)})
  end

  defp assign_form(socket) do
    transform_errors = fn
      _, %{class: :forbidden} ->
        {nil, "Forbidden", []}

      _, other ->
        if AshPhoenix.FormData.Error.impl_for(other) do
          other
        else
          {nil, "Internal Error: " <> Exception.message(other), []}
        end
    end

    auto_forms =
      AshPhoenix.Form.Auto.auto(socket.assigns.resource, socket.assigns.action.name,
        include_non_map_types?: true
      )

    form =
      case socket.assigns.action.type do
        :create ->
          socket.assigns.resource
          |> AshPhoenix.Form.for_create(socket.assigns.action.name,
            domain: socket.assigns.domain,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            forms: auto_forms,
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )

        :update ->
          socket.assigns.record
          |> AshPhoenix.Form.for_update(socket.assigns.action.name,
            domain: socket.assigns.domain,
            forms: auto_forms,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )

        :destroy ->
          socket.assigns.record
          |> AshPhoenix.Form.for_destroy(socket.assigns.action.name,
            domain: socket.assigns.domain,
            forms: auto_forms,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )
      end

    assign(socket, :form, form |> to_form())
  end

  defp collect_forms_recursively(%AshPhoenix.Form{} = form) do
    collect_recursive(form, [])
  end

  defp collect_recursive(form, acc) do
    acc = [form | acc]

    children = List.flatten(Map.values(form.forms))

    Enum.reduce(children, acc, fn child, acc ->
      collect_recursive(child, acc)
    end)
  end

  defp uploadable_arguments(form) do
    Enum.filter(form.source.action.arguments, fn %{type: type} -> type == Ash.Type.File end)
  end

  defp allow_uploading_form_arguments(socket) do
    socket.assigns.form.source
    |> collect_forms_recursively()
    |> Enum.flat_map(fn form ->
      form
      |> uploadable_arguments()
      |> Enum.map(fn argument ->
        %{
          upload_key: upload_key(form, argument),
          field: AshAdmin.Resource.field(form.resource, argument.name)
        }
      end)
    end)
    |> Enum.reduce(socket, fn %{upload_key: upload_key, field: field}, socket ->
      field = field || %{accepted_extensions: :any, max_file_size: 8_000_000}

      if upload_allowed?(socket, upload_key) do
        socket
      else
        allow_upload(socket, upload_key,
          accept: field.accepted_extensions || :any,
          # 8 megabyte (SI) default
          max_file_size: field.max_file_size || 8_000_000
        )
      end
    end)
  end

  defp upload_allowed?(socket, upload_key) do
    Map.get(socket.assigns, :uploads, %{})[upload_key]
  end

  defp upload_key(form, %Ash.Resource.Actions.Argument{name: name}) do
    "#{form.name}[#{name}]"
  end

  defp upload_key(form, %Ash.Resource.Attribute{name: name}) do
    "#{form.name}[#{name}]"
  end

  defp error_to_string(:too_large), do: "The file is too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
