defmodule AshAdmin.Components.Resource.Form do
  @moduledoc false
  use Phoenix.LiveComponent

  import AshAdmin.Helpers
  import Tails
  import AshAdmin.CoreComponents

  require Logger

  attr :resource, :any, required: true
  attr :api, :any, required: true
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
     |> assign_new(:loaded, fn -> %{} end)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()
     |> assign(:initialized, true)}
  end

  def render(assigns) do
    ~H"""
    <div class="md:pt-10 sm:mt-0 bg-gray-300 min-h-screen">
      <div class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          <%= render_form(assigns) %>
        </div>
      </div>

      <div :if={@type != :create} class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:mt-10">
        <div class="mt-5 md:mt-0 md:col-span-2">
          <%= AshAdmin.Components.Resource.Show.render_show(
            assigns,
            @record,
            @resource,
            "Original Record",
            false
          ) %>
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
        {Enum.join(List.wrap(path) ++ List.wrap(field), "."), message}
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
              <%= field %>:
            </span>
            <span>
              <%= message %>
            </span>
          </li>
        </ul>
      </div>
      <h1 class="text-lg mt-2 ml-4">
        <%= String.capitalize(to_string(@action.type)) %> <%= AshAdmin.Resource.name(@resource) %>
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
          <%= Phoenix.HTML.Form.select(form, :action, actions(@resource, @type),
            disabled: Enum.count(actions(@resource, @type)) <= 1,
            selected: to_string(@action.name)
          ) %>
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
          id={"#{@id}_form"}
        >
          <.input
            :for={kv <- form.hidden}
            name={form.name <> "[#{elem(kv, 0)}]"}
            value={elem(kv, 1)}
            type="hidden"
          />
          <%= render_attributes(assigns, @resource, @action, form) %>
          <div class="px-4 py-3 text-right sm:px-6">
            <button
              type="submit"
              class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <%= save_button_text(@type) %>
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
        <div phx-feedback-for={@form.name <> "[#{attribute.name}]"}>
          <label
            class="block text-sm font-medium text-gray-700"
            for={@form.name <> "[#{attribute.name}]"}
          >
            <%= to_name(attribute.name) %>
          </label>
          <%= render_attribute_input(assigns, attribute, @form) %>
          <.error_tag
            :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
            :if={!Ash.Type.embedded_type?(attribute.type)}
          >
            <%= replace_vars(error, vars) %>
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
          <%= to_name(attribute.name) %>
        </label>
        <%= render_attribute_input(assigns, attribute, @form) %>
        <.error_tag
          :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
          :if={!Ash.Type.embedded_type?(attribute.type)}
        >
          <%= replace_vars(error, vars) %>
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
          <%= to_name(attribute.name) %>
        </label>
        <%= render_attribute_input(assigns, attribute, @form) %>
        <.error_tag
          :for={{error, vars} <- Keyword.get_values(@form.errors || [], attribute.name)}
          :if={!Ash.Type.embedded_type?(attribute.type)}
        >
          <%= replace_vars(error, vars) %>
        </.error_tag>
      </div>
    </div>
    <div :for={{relationship, argument, opts} <- relationship_args}>
      <%= if relationship not in @skip and argument.name not in @skip do %>
        <label
          class="block text-sm font-medium text-gray-700"
          for={@form.name <> "[#{argument.name}]"}
        >
          <%= to_name(argument.name) %>
        </label>
        <%= render_relationship_input(
          assigns,
          Ash.Resource.Info.relationship(@form.source.resource, relationship),
          @form,
          argument,
          opts
        ) %>
      <% end %>
    </div>
    """
  end

  @spec error_tag(any()) :: Phoenix.LiveView.Rendered.t()
  def error_tag(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
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
        exactly_fields: exactly_fields
      )

    ~H"""
    <div :if={!must_load?(@opts) || loaded?(@form.source.source, @relationship.name)}>
      <.inputs_for :let={inner_form} field={@form[@argument.name]}>
        <div :if={@form.source.submitted_once?} class="ml-4 mt-4 text-red-500">
          <ul>
            <li :for={{field, message} <- AshPhoenix.Form.errors(inner_form.source)}>
              <span :if={field}>
                <%= to_name(field) %>:
              </span>
              <span>
                <%= message %>
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
            <%= render_attributes(
              assigns,
              @relationship.through,
              join_action(@relationship.through, join_form, inner_form.source.form_keys[:_join]),
              join_form,
              @exactly_fields || inner_form.source.form_keys[:_join][:create_fields],
              skip_through_related(@exactly_fields, @relationship)
            ) %>
          </.inputs_for>
        <% end %>
        <%= render_attributes(
          assigns,
          inner_form.source.resource,
          inner_form.source.source.action,
          inner_form,
          @exactly_fields || relationship_fields(inner_form),
          skip_related(@exactly_fields, @relationship)
        ) %>

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
        <%= Exception.message(@load_errors[@relationship.name]) %>
      </div>
      <div :if={@load_errors[@relationship.name] && !is_exception(@load_errors[@relationship.name])}>
        <%= inspect(@load_errors[@relationship.name]) %>
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

  def render_attribute_input(assigns, attribute, form, value \\ nil, name \\ nil)

  def render_attribute_input(assigns, %{type: Ash.Type.Date} = attribute, form, value, name) do
    assigns = assign(assigns, form: form, value: value, name: name, attribute: attribute)

    ~H"""
    <.input
      type="date"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@form.id <> "_#{@attribute.name}"}
    />
    """
  end

  def render_attribute_input(assigns, %{type: type} = attribute, form, value, name)
      when type in [Ash.Type.UtcDatetime, Ash.Type.UtcDatetimeUsec] do
    assigns = assign(assigns, form: form, value: value, name: name, attribute: attribute)

    ~H"""
    <.input
      type="datetime-local"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@form.id <> "_#{@attribute.name}"}
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
        name
      ) do
    assigns = assign(assigns, attribute: attribute, form: form, value: value, name: name)

    ~H"""
    <.input
      type="checkbox"
      value={value(@value, @form, @attribute)}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@form.id <> "_#{@attribute.name}"}
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
    assigns = assign(assigns, attribute: attribute, form: form, value: value, name: name)

    ~H"""
    <%= Phoenix.HTML.Form.select(
      @form,
      @attribute.name,
      [True: "true", False: "false"],
      prompt: allow_nil_option(@attribute, @value),
      selected: value(@value, @form, @attribute, "true"),
      name: @name || @form.name <> "[#{@attribute.name}]"
    ) %>
    """
  end

  def render_attribute_input(assigns, %{type: Ash.Type.Binary}, _form, _value, _name) do
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
        name
      )
      when type in [Ash.Type.CiString, Ash.Type.String, Ash.Type.UUID, Ash.Type.Atom] do
    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        type: type,
        name: name,
        default: default
      )

    ~H"""
    <%= cond do %>
      <% @type == Ash.Type.Atom && @attribute.constraints[:one_of] -> %>
        <%= Phoenix.HTML.Form.select(
          @form,
          @attribute.name,
          Enum.map(@attribute.constraints[:one_of], &{to_name(&1), &1}),
          selected: value(@value, @form, @attribute, List.first(@attribute.constraints[:one_of])),
          prompt: allow_nil_option(@attribute, @value),
          name: @name || @form.name <> "[#{@attribute.name}]"
        ) %>
      <% markdown?(@form.source.resource, @attribute) -> %>
        <div
          phx-hook="MarkdownEditor"
          id={@form.id <> "_#{@attribute.name}_container"}
          phx-update="ignore"
          data-target-id={@form.id <> "_#{@attribute.name}"}
          class="prose max-w-none"
        >
          <textarea
            id={@form.id <> "_#{@attribute.name}"}
            class="prose max-w-none"
            name={@name || @form.name <> "[#{@attribute.name}]"}
          ><%= value(@value, @form, @attribute) || "" %></textarea>
        </div>
      <% long_text?(@form.source.resource, @attribute) -> %>
        <textarea
          id={@form.id <> "_#{@attribute.name}"}
          name={@name || @form.name <> "[#{@attribute.name}]"}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md resize-y"
          phx-hook="MaintainAttrs"
          data-attrs="style"
          placeholder={placeholder(@default)}
        ><%= value(@value, @form, @attribute) %></textarea>
      <% short_text?(@form.source.resource, @attribute) -> %>
        <.input
          type={text_input_type(@form.source.resource, @attribute)}
          id={@form.id <> "_#{@attribute.name}"}
          value={value(@value, @form, @attribute)}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={@name || @form.name <> "[#{@attribute.name}]"}
          placeholder={placeholder(@default)}
        />
      <% true -> %>
        <.input
          type={text_input_type(@form.source.resource, @attribute)}
          placeholder={placeholder(@default)}
          id={@form.id <> "_#{@attribute.name}"}
          value={value(@value, @form, @attribute)}
          class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          name={@name || @form.name <> "[#{@attribute.name}]"}
        />
    <% end %>
    """
  end

  def render_attribute_input(
        assigns,
        %{type: {:array, Ash.Type.Map}} = attribute,
        form,
        value,
        name
      ) do
    render_attribute_input(assigns, %{attribute | type: Ash.Type.Map}, form, value, name)
  end

  def render_attribute_input(assigns, %{type: Ash.Type.Map} = attribute, form, value, name) do
    encoded = Jason.encode!(value(value, form, attribute))

    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name,
        encoded: encoded
      )

    ~H"""
    <div>
      <div
        phx-hook="JsonEditor"
        phx-update="ignore"
        data-input-id={@form.id <> "_#{@attribute.name}"}
        id={@form.id <> "_#{@attribute.name}_json"}
      />

      <.input
        type="hidden"
        phx-hook="JsonEditorSource"
        data-editor-id={@form.id <> "_#{@attribute.name}_json"}
        value={@encoded}
        name={@name || @form.name <> "[#{@attribute.name}]"}
        id={@form.id <> "_#{@attribute.name}"}
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

  def render_attribute_input(assigns, attribute, form, value, name) do
    assigns =
      assign(assigns,
        attribute: attribute,
        form: form,
        value: value,
        name: name
      )

    ~H"""
    <%= cond do %>
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

          <%= render_attributes(
            assigns,
            inner_form.source.resource,
            inner_form.source.source.action,
            inner_form
          ) %>
        </.inputs_for>
        <button
          :if={can_append_embed?(@form.source.source, @attribute.name)}
          type="button"
          phx-click="add_form"
          phx-target={@myself}
          phx-value-pkey={embedded_type_pkey(@attribute.type)}
          phx-value-path={@name || @form.name <> "[#{@attribute.name}]"}
          class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
        >
          <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
        </button>
      <% is_atom(@attribute.type) && function_exported?(@attribute.type, :values, 0) -> %>
        <%= Phoenix.HTML.Form.select(
          @form,
          @attribute.name,
          Enum.map(@attribute.type.values(), &{to_name(&1), &1}),
          selected: value(@value, @form, @attribute, List.first(@attribute.type.values())),
          prompt: allow_nil_option(@attribute, @value),
          name: @name || @form.name <> "[#{@attribute.name}]"
        ) %>
      <% true -> %>
        <%= render_fallback_attribute(assigns, @form, @attribute, @value, @name) %>
    <% end %>
    """
  end

  defp render_fallback_attribute(assigns, form, %{type: {:array, type}} = attribute, value, name) do
    name = name || form.name <> "[#{attribute.name}]"

    assigns =
      assign(assigns, form: form, attribute: attribute, type: type, value: value, name: name)

    ~H"""
    <div>
      <div :for={
        {this_value, index} <-
          Enum.with_index(
            list_value(
              @value || Phoenix.HTML.FormData.input_value(@form.source, @form, @attribute.name)
            )
          )
      }>
        <%= render_attribute_input(
          assigns,
          %{@attribute | type: @type, constraints: @attribute.constraints[:items] || []},
          %{
            @form
            | params: %{"#{@attribute.name}" => @form.params["#{@attribute.name}"]["#{index}"]}
          },
          {:list_value, this_value},
          @name <> "[#{index}]"
        ) %>
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
        class="flex h-6 w-6 mt-2 border-gray-600 hover:bg-gray-400 rounded-md justify-center items-center"
      >
        <.icon name="hero-plus" class="h-4 w-4 text-gray-500" />
      </button>
    </div>
    """
  end

  defp render_fallback_attribute(assigns, form, attribute, value, name) do
    casted_value = Phoenix.HTML.Safe.to_iodata(value(value, form, attribute))

    assigns =
      assign(assigns,
        casted_value: casted_value,
        form: form,
        attribute: attribute,
        value: value,
        name: name
      )

    ~H"""
    <.input
      type={text_input_type(@form.source.resource, @attribute)}
      placeholder={placeholder(@attribute.default)}
      value={@casted_value}
      name={@name || @form.name <> "[#{@attribute.name}]"}
      id={@form.id <> "_#{@attribute.name}"}
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
            value={@value}
            name={@name || @form.name <> "[#{@attribute.name}]"}
            id={@form.id <> "_#{@attribute.name}"}
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
            id={@form.id <> "_#{@attribute.name}"}
            class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
          />
          """
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
      if Ash.Resource.Info.attribute(type, attr).private? do
        []
      else
        [attr]
      end
    end)
    |> Enum.join("-")
  end

  defp value(value, form, attribute, default \\ nil)

  defp value({:list_value, nil}, _, _, default), do: default
  defp value({:list_value, value}, _, _, _), do: value

  defp value(value, _form, _attribute, _) when not is_nil(value), do: value

  defp value(_value, form, attribute, default) do
    value = Phoenix.HTML.FormData.input_value(form.source, form, attribute.name)

    case value do
      nil ->
        case attribute.default do
          nil ->
            default

          func when is_function(func) ->
            default

          attribute_default ->
            attribute_default
        end

      value ->
        value
    end
  end

  defp allow_nil_option(_, {:list_value, _}), do: "-"
  defp allow_nil_option(%{allow_nil?: true}, _), do: "-"

  defp allow_nil_option(%{default: default, allow_nil?: false}, _) when not is_nil(default),
    do: nil

  defp allow_nil_option(_, _), do: "Select an option"

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
           "#{socket.assigns.prefix || "/"}?api=#{AshAdmin.Api.name(socket.assigns.api)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}&tab=show&table=#{socket.assigns.table}&primary_key=#{encode_primary_key(record)}"
       )}
    else
      case AshAdmin.Helpers.primary_action(socket.assigns.resource, :update) do
        nil ->
          {:noreply,
           redirect(socket,
             to:
               "#{socket.assigns.prefix || "/"}?api=#{AshAdmin.Api.name(socket.assigns.api)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}"
           )}

        _update ->
          {:noreply,
           socket
           |> redirect(
             to:
               "#{socket.assigns.prefix || "/"}?api=#{AshAdmin.Api.name(socket.assigns.api)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}&action_type=update&tab=update&table=#{socket.assigns.table}&primary_key=#{encode_primary_key(record)}"
           )}
      end
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

  def handle_event("append_value", %{"path" => path, "field" => field}, socket) do
    form =
      AshPhoenix.Form.update_form(
        socket.assigns.form,
        path,
        fn adding_form ->
          new_value =
            adding_form
            |> Phoenix.HTML.Form.form_for("foo")
            |> Phoenix.HTML.Form.input_value(String.to_existing_atom(field))
            |> Kernel.||([])
            |> indexed_list()
            |> append_to_and_map(nil)

          new_params =
            Map.put(
              adding_form.params,
              field,
              new_value
            )

          AshPhoenix.Form.validate(adding_form, new_params)
        end
      )

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
            new_data = socket.assigns.api.load!(adding_form.data, relationship)

            if Map.has_key?(adding_form.source, :data) do
              %{adding_form | data: new_data, source: %{adding_form.source | data: new_data}}
            else
              %{adding_form | data: new_data}
            end
            |> AshPhoenix.Form.validate(adding_form.params, errors: false)
          else
            adding_form
          end
        end
      )
      |> AshPhoenix.Form.validate(AshPhoenix.Form.params(socket.assigns.form))

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

  def handle_event("save", _, socket) do
    form = socket.assigns.form

    before_submit = fn changeset ->
      changeset
      |> set_table(socket.assigns[:table])
      |> Map.put(:actor, socket.assigns[:actor])
    end

    case AshPhoenix.Form.submit(form,
           params: form.source.params,
           before_submit: before_submit,
           force?: true
         ) do
      {:ok, result} ->
        redirect_to(socket, result)

      :ok ->
        {:noreply,
         socket
         |> redirect(
           to:
             "#{socket.assigns.prefix}?api=#{AshAdmin.Api.name(socket.assigns.api)}&resource=#{AshAdmin.Resource.name(socket.assigns.resource)}"
         )}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  def handle_event("validate", %{"form" => params, "_target" => target}, socket) do
    params =
      case target do
        [_] ->
          socket.assigns.form.params

        target ->
          put_in_creating(
            socket.assigns.form.params || %{},
            tl(target),
            get_in(params, tl(target))
          )
      end

    form = AshPhoenix.Form.validate(socket.assigns.form, params || %{})

    {:noreply, assign(socket, :form, form)}
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
    arguments =
      action.arguments
      |> Enum.reject(& &1.private?)

    attributes =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(& &1.writable?)
      |> Enum.reject(&(&1.private? || &1.name == :autogenerated_id))
      |> only_accepted(action)
      |> Enum.reject(fn attribute ->
        Enum.any?(arguments, &(&1.name == attribute.name))
      end)

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
    Enum.filter(attributes, &(&1.name in accept && &1.name not in (reject || [])))
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
    transform_errors = fn
      _, %{class: :forbidden} ->
        {nil, "Forbidden", []}

      _, other ->
        other
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
            api: socket.assigns.api,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            forms: auto_forms,
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )

        :update ->
          socket.assigns.record
          |> AshPhoenix.Form.for_update(socket.assigns.action.name,
            api: socket.assigns.api,
            forms: auto_forms,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )

        :destroy ->
          socket.assigns.record
          |> AshPhoenix.Form.for_destroy(socket.assigns.action.name,
            api: socket.assigns.api,
            forms: auto_forms,
            actor: socket.assigns[:actor],
            authorize?: socket.assigns[:authorizing],
            transform_errors: transform_errors,
            tenant: socket.assigns[:tenant]
          )
      end

    assign(socket, :form, form |> to_form())
  end
end
