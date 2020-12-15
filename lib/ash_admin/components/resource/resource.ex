defmodule AshAdmin.Components.Resource do
  use Surface.LiveComponent

  import AshAdmin.Helpers
  require Ash.Query

  alias AshAdmin.Components.Resource.{Form, Info, Nav}
  alias AshPhoenix.Components.{DataTable, FilterBuilder}
  alias Surface.Components.LiveRedirect

  # prop hide_filter, :boolean, default: true
  prop resource, :any, required: true
  prop api, :any, required: true
  prop tab, :string, required: true
  prop action, :any
  prop actor, :any, required: true
  prop set_actor, :event, required: true
  prop authorize, :boolean, required: true
  prop tenant, :string, required: true
  prop recover_filter, :any
  prop page_params, :any, default: []
  prop page_num, :integer, default: 1
  prop url_path, :string, default: ""
  prop params, :map, default: %{}
  prop primary_key, :any, default: nil
  prop record, :any, default: nil

  data filter_open, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="content-center">
      <Nav
        resource={{ @resource }}
        api={{ @api }}
        tab={{ @tab }}
        action={{ @action }}/>
      <div class="mx-24 relative grid grid-cols-1 justify-items-center">
        <FilterBuilder
          :if={{@tab == "data" && @action.type == :read && @filter_open && !@record}}
          id={{data_table_id(@resource) <> "_id"}}
          class="my-6 border-2 rounded max-w-5xl p-2 border-gray-600 bg-gray-300"
          header_class="flex justify-between w-full mb-2 h-6"
          operator_toggle_container_class="flex items-baseline"
          actions_container_class="flex items-baseline float-right"
          filter_form_class="flex items-center h-6 my-2"
          filter_input_group_class="flex items-center h-6"
          filter_input_class="mx-1"
          recover_filter={{@recover_filter}}
          resource={{@resource}}
          table_id={{data_table_id(@resource)}}
          >
          <template slot="play_button" :let={{active: active, on_click: on_click, target: target}}>
            <button :if={{active}} :on-click={{on_click, target: target}} class="bg-green-700 w-20 h-8 rounded text-white flex justify-center items-center mx-1 mt-3 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M11.596 8.697l-6.363 3.692c-.54.313-1.233-.066-1.233-.697V4.308c0-.63.692-1.01 1.233-.696l6.363 3.692a.802.802 0 0 1 0 1.393z"/>
              </svg>
              <span class="text-white">
                Play
              </span>
            </button>
          </template>
          <template slot="pause_button" :let={{active: active, on_click: on_click, target: target}}>
            <button :if={{active}} :on-click={{on_click, target: target}} class="bg-yellow-600 w-20 h-8 rounded text-white flex justify-center items-center mx-1 mt-3 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M5.5 3.5A1.5 1.5 0 0 1 7 5v6a1.5 1.5 0 0 1-3 0V5a1.5 1.5 0 0 1 1.5-1.5zm5 0A1.5 1.5 0 0 1 12 5v6a1.5 1.5 0 0 1-3 0V5a1.5 1.5 0 0 1 1.5-1.5z"/>
                <span class="text-white">
                  Pause
                </span>
              </svg>
            </button>
          </template>
          <template slot="toggle_operator_button" :let={{location: location, group: group, on_click: on_click, target: target}}>
            <button
            :if={{group && Enum.count(group.filters) > 1 }}
            phx-value-location={{location}}
            :on-click={{on_click, target: target}}
            class={{"h-full w-10 rounded-l text-white flex justify-center items-center text-lg", "bg-blue-900": group.operator == :and, "bg-blue-500": group.operator == :or}}>
              And
            </button>
            <button
            :if={{group && Enum.count(group.filters) > 1 }}
            phx-value-location={{location}}
            :on-click={{on_click, target: target}}
            class={{"h-full w-10 rounded-r text-white flex justify-center items-center text-lg", "bg-blue-900": group.operator == :or, "bg-blue-500": group.operator == :and}}>
              Or
            </button>
          </template>
          <template slot="create_filter_button" :let={{on_click: on_click, target: target}}>
            <button :on-click={{on_click, target: target}} class="inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500 m-5">
              Add Filter
            </button>
          </template>
          <template slot="add_group_button" :let={{on_click: on_click, target: target, location: location}}>
            <button :on-click={{on_click, target: target}} phx-value-location={{location}} class="bg-blue-900 h-full w-8 rounded text-white flex justify-center items-center mx-1 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M11 4a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM6.025 7.5a5 5 0 1 1 0 1H4A1.5 1.5 0 0 1 2.5 10h-1A1.5 1.5 0 0 1 0 8.5v-1A1.5 1.5 0 0 1 1.5 6h1A1.5 1.5 0 0 1 4 7.5h2.025zM11 5a.5.5 0 0 1 .5.5v2h2a.5.5 0 0 1 0 1h-2v2a.5.5 0 0 1-1 0v-2h-2a.5.5 0 0 1 0-1h2v-2A.5.5 0 0 1 11 5zM1.5 7a.5.5 0 0 0-.5.5v1a.5.5 0 0 0 .5.5h1a.5.5 0 0 0 .5-.5v-1a.5.5 0 0 0-.5-.5h-1z"/>
              </svg>
            </button>
          </template>
          <template slot="add_filter_button" :let={{on_click: on_click, target: target, location: location}}>
            <button :on-click={{on_click, target: target}} phx-value-location={{location}} class="bg-blue-900 h-full rounded w-8 text-white flex justify-center items-center mx-1 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M14 1H2a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1zM2 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2z"></path>
                <path fill-rule="evenodd" d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4z"></path>
              </svg>
            </button>
          </template>
          <template slot="remove_group_button" :let={{on_click: on_click, target: target, location: location}}>
            <button type="button" :on-click={{on_click, target: target}} phx-value-location={{location}} class="bg-red-600 h-full w-8 rounded text-white flex justify-center items-center mx-1 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/>
                <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4L4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/>
              </svg>
            </button>
          </template>
          <template slot="remove_group_button" :let={{on_click: on_click, target: target, location: location}}>
            <button type="button" :on-click={{on_click, target: target}} phx-value-location={{location}} class="bg-red-600 h-full w-8 rounded text-white flex justify-center items-center mx-1 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/>
                <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4L4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/>
              </svg>
            </button>
          </template>
          <template slot="remove_filter_button" :let={{on_click: on_click, target: target, location: location}}>
            <button type="button" :on-click={{on_click, target: target}} phx-value-location={{location}} class="bg-red-600 h-full w-8 rounded text-white flex justify-center items-center mx-1 text-lg">
              <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/>
                <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4L4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/>
              </svg>
            </button>
          </template>
        </FilterBuilder>
        <div class="mx-24 relative grid grid-cols-1 justify-items-center">
          <div :if={{@tab == "data" && @action.type == :read && !@filter_open && !@record}}>
            <button :on-click="toggle_filter" class="inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500 m-5">
              Add Filter
            </button>
          </div>
          <div :if={{@tab == "data" && @action.type == :read && @filter_open && !@record}}>
            <button :on-click="toggle_filter" class="inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-indigo-500 m-5">
              Clear Filter
            </button>
          </div>
        </div>
        <DataTable
          class="w-full rounded"
          :if={{@tab == "data" && @action.type == :read && !@record}}
          id={{data_table_id(@resource)}}
          resource={{ @resource }}
          api={{ @api }}
          recover_filter={{@recover_filter}}
          run_query={{run_query()}}
          query_context={{%{resource: @resource, api: @api, action: @action, authorize?: @authorize, tenant: @tenant, actor: @actor, page_params: @page_params}}}
          show_header=true
          table_class="table-auto text-left w-full"
          thead_class="sticky top-0 w-full"
          even_tr_class="bg-gray-200"
          pagination_footer_container_class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
          loading=true>
            <template slot="actions" :let={{ item: item }}>
              <div class="flex align-items-center gap-2">
                <LiveRedirect :if={{Ash.Resource.primary_action(@resource, :read)}} to={{ash_update_path(@socket, @api, @resource, item)}} class="mr-1">
                  <svg width="1em" height="1em" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M17.414 2.586a2 2 0 00-2.828 0L7 10.172V13h2.828l7.586-7.586a2 2 0 000-2.828z" />
                    <path fill-rule="evenodd" d="M2 6a2 2 0 012-2h4a1 1 0 010 2H4v10h10v-4a1 1 0 112 0v4a2 2 0 01-2 2H4a2 2 0 01-2-2V6z" clip-rule="evenodd" />
                  </svg>
                </LiveRedirect>
                <button
                :if={{AshAdmin.Resource.actor?(@resource)}}
                slot="actions"
                type="button"
                :on-click={{@set_actor}}
                phx-value-resource={{@resource}}
                phx-value-api={{@api}}
                phx-value-action={{@action.name}}
                phx-value-pkey={{encode_primary_key(item)}}>
                  <svg width="1em" height="1em" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                    <path fill-rule="evenodd" d="M0 8a4 4 0 0 1 7.465-2H14a.5.5 0 0 1 .354.146l1.5 1.5a.5.5 0 0 1 0 .708l-1.5 1.5a.5.5 0 0 1-.708 0L13 9.207l-.646.647a.5.5 0 0 1-.708 0L11 9.207l-.646.647a.5.5 0 0 1-.708 0L9 9.207l-.646.647A.5.5 0 0 1 8 10h-.535A4 4 0 0 1 0 8zm4-3a3 3 0 1 0 2.712 4.285A.5.5 0 0 1 7.163 9h.63l.853-.854a.5.5 0 0 1 .708 0l.646.647.646-.647a.5.5 0 0 1 .708 0l.646.647.646-.647a.5.5 0 0 1 .708 0l.646.647.793-.793-1-1h-6.63a.5.5 0 0 1-.451-.285A3 3 0 0 0 4 5z"/>
                    <path d="M4 8a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"/>
                  </svg>
                </button>
              </div>
            </template>
            <template slot="error" :let={{ error: error}}>
              {{ inspect(error) }}
            </template>
            <template slot="left_footer" :let={{ data: data}}>
              <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                <div :if={{offset?(data)}}>
                  <p class="text-sm text-gray-700">
                    Showing
                    <span class="font-medium">{{offset(data) + 1}}</span>
                    to
                    <span class="font-medium">{{offset(data) + min(limit(data), Enum.count(data(data)))}}</span>
                    <span :if={{count(data)}}>
                      of
                      <span class="font-medium">{{count(data)}}</span>
                    </span>
                    results
                  </p>
                </div>
              </div>

              <div :if={{keyset?(data)}}>
                <p class="text-sm text-gray-700">
                  Showing
                  <span class="font-medium">{{Enum.count(data(data))}}</span>
                  <span :if={{count(data)}}>
                    of
                    <span class="font-medium">{{count(data)}}</span>
                  </span>
                  results
                </p>
              </div>
            </template>
            <template slot="right_footer" :let={{ data: data}}>
              <nav class="relative z-0 inline-flex shadow-sm -space-x-px" aria-label="Pagination">
                <LiveRedirect
                :if={{page_link_params(data, "prev")}}
                to={{self_path(@url_path, @params, page_link_params(data, "prev"))}}
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                  <span class="sr-only">Previous</span>
                  <!-- Heroicon name: chevron-left -->
                  <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                </LiveRedirect>
                <LiveRedirect
                  :for={{page_num <- leading_page_nums(data)}}
                  to={{self_path(@url_path, @params, page_link_params(data, page_num))}}
                  class={{"relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700", "hover:bg-gray-50": page_num != @page_num, "bg-gray-300": page_num == @page_num}}>
                  {{page_num}}
                </LiveRedirect>
                <span
                :if={{show_ellipses?(data)}}
                class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                  {{middle_page_num(@page_num, trailing_page_nums(data))}}
                </span>
                <LiveRedirect
                  :for={{ page_num <- trailing_page_nums(data) }}
                  to={{self_path(@url_path, @params, page_link_params(data, page_num))}}
                  class={{"relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700", "hover:bg-gray-50": page_num != @page_num, "bg-gray-300": page_num == @page_num}}>
                  {{ page_num }}
                </LiveRedirect>
                <LiveRedirect
                  :if={{page_link_params(data, "next")}}
                  to={{self_path(@url_path, @params, page_link_params(data, "next"))}}
                  class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                  >
                  <span class="sr-only">Next</span>
                  <!-- Heroicon name: chevron-right -->
                  <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                  </svg>
                </LiveRedirect>
              </nav>
            </template>
        </DataTable>
      </div>
      <div :if={{@record && match?({:ok, record} when not is_nil(record), @record) && @tab == "update"}}>
        {{{:ok, record} = @record; nil}}
        <Form type={{:update}} record={{record}} resource={{@resource}} api={{@api}} id={{update_id(@resource)}}/>
      </div>
      <Info :if={{@tab == "info"}} resource={{@resource}} api={{@api}}/>
      <Form :if={{@tab == "create"}} type={{:create}} resource={{@resource}} api={{@api}} id={{create_id(@resource)}}/>
    </div>
    """
  end

  defp middle_page_num(num, trailing_page_nums) do
    if num in trailing_page_nums || num <= 3 do
      "..."
    else
      "...#{num}..."
    end
  end

  defp page_link_params({:ok, page}, target), do: page_link_params(page, target)

  defp page_link_params(page, target) do
    case AshPhoenix.LiveView.page_link_params(page, target) do
      :invalid ->
        nil

      params ->
        [page: params]
    end
  end

  defp show_ellipses?(%Ash.Page.Offset{count: count, limit: limit}) when not is_nil(count) do
    page_nums =
      count
      |> Kernel./(limit)
      |> Float.ceil()
      |> trunc()

    page_nums > 6
  end

  defp show_ellipses?({:ok, data}), do: show_ellipses?(data)
  defp show_ellipses?(_), do: false

  def leading_page_nums({:ok, data}), do: leading_page_nums(data)
  def leading_page_nums(%Ash.Page.Offset{count: nil}), do: []

  def leading_page_nums(%Ash.Page.Offset{limit: limit, count: count}) do
    page_nums =
      count
      |> Kernel./(limit)
      |> Float.ceil()
      |> trunc()

    1..min(3, page_nums)
  end

  def leading_page_nums(_), do: []

  def trailing_page_nums({:ok, data}), do: trailing_page_nums(data)
  def trailing_page_nums(%Ash.Page.Offset{count: nil}), do: []

  def trailing_page_nums(%Ash.Page.Offset{limit: limit, count: count}) do
    page_nums =
      count
      |> Kernel./(limit)
      |> Float.ceil()
      |> trunc()

    if page_nums > 3 do
      max(page_nums - 2, 0)..page_nums
    else
      []
    end
  end

  def handle_event("toggle_filter", _, socket) do
    {:noreply, assign(socket, :filter_open, !socket.assigns.filter_open)}
  end

  defp data({:ok, data}), do: data(data)
  defp data(%Ash.Page.Offset{results: results}), do: results
  defp data(%Ash.Page.Keyset{results: results}), do: results
  defp data(_), do: []

  defp offset?({:ok, data}), do: offset?(data)
  defp offset?(%Ash.Page.Offset{}), do: true
  defp offset?(_), do: false

  defp keyset?({:ok, data}), do: keyset?(data)
  defp keyset?(%Ash.Page.Keyset{}), do: true
  defp keyset?(_), do: false

  defp offset({:ok, data}), do: offset(data)
  defp offset(%Ash.Page.Offset{offset: offset}), do: offset
  defp offset(_), do: 0

  defp limit({:ok, data}), do: limit(data)
  defp limit(%Ash.Page.Offset{limit: limit}), do: limit
  defp limit(_), do: 0

  defp count({:ok, %{count: count}}), do: count
  defp count(%{count: count}), do: count
  defp count(_), do: nil

  defp data_table_id(resource) do
    "#{resource}_table"
  end

  defp create_id(resource) do
    "#{resource}_create"
  end

  defp update_id(resource) do
    "#{resource}_update"
  end

  defp run_query() do
    fn filter, sort, fields, context ->
      page_params =
        case context.action.pagination do
          false ->
            false

          %{offset?: true} ->
            context[:page_params] || [offset: 0]

          _ ->
            context[:page_params]
        end

      context.resource
      |> Ash.Query.filter(^filter)
      |> Ash.Query.sort(sort)
      |> Ash.Query.load(fields)
      |> Ash.Query.set_tenant(context.tenant)
      |> context.api.read(
        page: page_params,
        action: context.action.name,
        actor: context.actor,
        authorize?: context.authorize?
      )
    end
  end
end
