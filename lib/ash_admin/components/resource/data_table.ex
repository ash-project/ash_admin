defmodule AshAdmin.Components.Resource.DataTable do
  @moduledoc false
  use Surface.LiveComponent

  import AshAdmin.Helpers
  import AshPhoenix.LiveView
  alias Surface.Components.Form
  alias AshAdmin.Components.Resource.Table

  prop(resource, :atom)
  prop(api, :atom)
  prop(action, :any)
  prop(authorizing, :boolean)
  prop(set_actor, :event, required: true)
  prop(actor, :any)
  prop(url_path, :any)
  prop(params, :any)
  prop(table, :any, required: true)
  prop(tables, :any, required: true)
  prop(prefix, :any, required: true)

  data(initialized, :boolean, default: false)
  data(data, :any)
  data(query, :any, default: nil)
  data(page_params, :any, default: nil)
  data(page_num, :any, default: nil)

  def update(assigns, socket) do
    if assigns[:initialized] do
      {:ok, socket}
    else
      socket = assign(socket, assigns)
      params = socket.assigns[:params] || %{}
      arguments = params["args"] || %{}

      query =
        socket.assigns[:resource]
        |> Ash.Query.for_read(socket.assigns.action.name, arguments)
        |> AshPhoenix.hide_errors()

      socket = assign(socket, :query, query)

      socket =
        if params["page"] do
          default_limit =
            (socket.assigns[:action] && socket.assigns.action.pagination &&
               socket.assigns.action.pagination.default_limit) ||
              socket.assigns.action.pagination.max_page_size || 25

          count? =
            socket.assigns[:action] && socket.assigns.action.pagination &&
              socket.assigns.action.pagination.countable

          page_params =
            AshPhoenix.LiveView.page_from_params(params["page"], default_limit, !!count?)

          socket
          |> assign(
            :page_params,
            page_params
          )
          |> assign(
            :page_num,
            page_num_from_page_params(page_params)
          )
        else
          socket
          |> assign(:page_params, nil)
          |> assign(:page_num, 1)
        end

      socket =
        if assigns[:action].pagination do
          keep_live(
            socket,
            :data,
            fn socket ->
              default_limit =
                socket.assigns[:action].pagination.default_limit ||
                  socket.assigns[:action].pagination.max_page_size || 25

              count? = socket.assigns[:action].pagination.countable

              page_params =
                if socket.assigns[:params]["page"] do
                  page_from_params(socket.assigns[:params]["page"], default_limit, !!count?)
                else
                  []
                end

              if AshAdmin.Resource.polymorphic?(socket.assigns.resource) &&
                   !socket.assigns[:table] do
                {:ok, []}
              else
                socket.assigns.query
                |> set_table(socket.assigns[:table])
                |> assigns[:api].read(
                  action: socket.assigns[:action].name,
                  actor: socket.assigns[:actor],
                  authorize?: socket.assigns[:authorizing],
                  page: page_params
                )
              end
            end,
            load_until_connected?: true
          )
        else
          keep_live(
            socket,
            :data,
            fn socket ->
              if AshAdmin.Resource.polymorphic?(socket.assigns.resource) &&
                   !socket.assigns[:table] do
                {:ok, []}
              else
                socket.assigns.query
                |> set_table(socket.assigns[:table])
                |> assigns[:api].read(
                  action: socket.assigns[:action],
                  actor: socket.assigns[:actor],
                  authorize?: socket.assigns[:authorizing]
                )
              end
            end,
            load_until_connected?: true
          )
        end

      {:ok,
       socket
       |> assign(:initialized, true)}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="sm:mt-0 bg-gray-300 min-h-screen">
        <div
          :if={{ @action.arguments != [] }}
          class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:pt-10 mb-10"
        >
          <div class="md:mt-0 md:col-span-2">
            <div class="shadow-lg overflow-hidden pt-2 sm:rounded-md bg-white">
              <div class="px-4 sm:p-6">
                <Form
                  :if={{ @query }}
                  as="query"
                  for={{ @query }}
                  change="validate"
                  submit="save"
                  :let={{ form: form }}
                >
                  {{ AshAdmin.Components.Resource.Form.render_attributes(assigns, @resource, @action, form) }}
                  <div class="px-4 py-3 text-right sm:px-6">
                    <button
                      type="submit"
                      class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Run Query
                    </button>
                  </div>
                </Form>
              </div>
            </div>
          </div>
        </div>

        <div
          :if={{ AshAdmin.Resource.polymorphic?(@resource) }}
          class="md:grid md:grid-cols-3 md:gap-6 md:mx-16 md:pt-10 mb-10"
        >
          <div class="md:mt-0 md:col-span-2">
            <div class="px-4 sm:p-6">
              <AshAdmin.Components.Resource.SelectTable
                resource={{ @resource }}
                on_change="change_table"
                table={{ @table }}
                tables={{ @tables }}
              />
            </div>
          </div>
        </div>

        <div :if={{ @action.arguments == [] || @params["args"] }} class="h-full overflow-scroll md:mx-4">
          <div class="shadow-lg overflow-scroll sm:rounded-md bg-white">
            <div :if={{ match?({:error, _}, @data) }}>
              {{ {:error, %{query: query}} = @data
              nil }}
              <ul>
                <li :for={{ error <- query.errors }}>
                  {{ message(error) }}
                </li>
              </ul>
            </div>
            <div class="px-2">
              {{ render_pagination_links(assigns, :top) }}
              <Table
                :if={{ match?({:ok, _data}, @data) }}
                table={{ @table }}
                data={{ data(@data) }}
                resource={{ @resource }}
                api={{ @api }}
                set_actor={{ @set_actor }}
                attributes={{ AshAdmin.Resource.table_columns(@resource) }}
                prefix={{ @prefix }}
              />
              {{ render_pagination_links(assigns, :bottom) }}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("next_page", _, socket) do
    params = %{"page" => page_link_params(socket.assigns.data, "next")}

    {:noreply,
     push_patch(socket, to: self_path(socket.assigns.url_path, socket.assigns.params, params))}
  end

  def handle_event("prev_page", _, socket) do
    params = %{"page" => page_link_params(socket.assigns.data, "prev")}

    {:noreply,
     push_patch(socket, to: self_path(socket.assigns.url_path, socket.assigns.params, params))}
  end

  def handle_event("specific_page", %{"page" => page}, socket) do
    params = %{"page" => page_link_params(socket.assigns.data, String.to_integer(page))}

    {:noreply,
     push_patch(socket, to: self_path(socket.assigns.url_path, socket.assigns.params, params))}
  end

  def handle_event("validate", %{"query" => query}, socket) do
    query = Ash.Query.for_read(socket.assigns.resource, socket.assigns.action.name, query)

    {:noreply, assign(socket, query: query)}
  end

  def handle_event("save", %{"query" => query_params}, socket) do
    {:noreply,
     push_redirect(
       socket,
       to: self_path(socket.assigns.url_path, socket.assigns.params, %{"args" => query_params})
     )}
  end

  def handle_event("change_table", %{"table" => %{"table" => table}}, socket) do
    {:noreply,
     push_redirect(socket,
       to:
         ash_action_path(
           socket,
           socket.assigns.api,
           socket.assigns.resource,
           socket.assigns.action.type,
           socket.assigns.action.name,
           table
         )
     )}
  end

  defp render_pagination_links(assigns, placement) do
    ~H"""
    <div
      :if={{ (offset?(@data) || keyset?(@data)) && show_pagination_links?(@data, placement) }}
      class="w-5/6 mx-auto"
    >
      <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
        <div class="flex-1 flex justify-between sm:hidden">
          <button
            :if={{ !(keyset?(@data) && is_nil(@params["page"])) && prev_page?(@data) }}
            :on-click="prev_page"
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:text-gray-500"
          >
            Previous
          </button>
          {{ render_pagination_information(assigns, true) }}
          <button
            :if={{ next_page?(@data) }}
            :on-click="next_page"
            class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:text-gray-500"
          >
            Next
          </button>
        </div>
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            {{ render_pagination_information(assigns) }}
          </div>
          <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
              <button
                :if={{ !(keyset?(@data) && is_nil(@params["page"])) && prev_page?(@data) }}
                :on-click="prev_page"
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
              >
                <span class="sr-only">Previous</span>

                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
              <span :if={{ offset?(@data) }}>
                {{ render_page_links(assigns, leading_page_nums(@data)) }}
                {{ render_middle_page_num(assigns, @page_num, trailing_page_nums(@data)) }}
                {{ render_page_links(assigns, trailing_page_nums(@data)) }}
              </span>
              <button
                :if={{ next_page?(@data) }}
                :on-click="next_page"
                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
              >
                <span class="sr-only">Next</span>

                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_page_links(assigns, page_nums) do
    ~H"""
    <button
      :on-click="specific_page"
      phx-value-page={{ i }}
      :for={{ i <- page_nums }}
      class={{
        "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50",
        "bg-gray-300": @page_num == i
      }}
    >
      {{ i }}
    </button>
    """
  end

  defp render_pagination_information(assigns, small? \\ false) do
    ~H"""
    <p class={{ "text-sm text-gray-700", "sm:hidden": small? }}>
      <span :if={{ offset?(@data) }}>
        Showing
        <span class="font-medium">{{ first(@data) }}</span>
        to
        <span class="font-medium">{{ last(@data) }}</span>
        of
      </span>
      <span :if={{ count(@data) }}>
        <span class="font-medium">{{ count(@data) }}</span>
        results
      </span>
    </p>
    """
  end

  defp page_num_from_page_params(params) do
    cond do
      !params[:offset] || params[:after] || params[:before] ->
        1

      params[:offset] && params[:limit] ->
        trunc(Float.ceil(params[:offset] / params[:limit])) + 1

      true ->
        nil
    end
  end

  defp show_pagination_links?({:ok, _page}, :bottom), do: true
  defp show_pagination_links?({:ok, page}, :top), do: page.limit >= 20
  defp show_pagination_links?(_, _), do: false

  defp first({:ok, %Ash.Page.Offset{offset: offset}}) do
    (offset || 0) + 1
  end

  defp first(_), do: nil

  defp last({:ok, %Ash.Page.Offset{offset: offset, results: results}}) do
    Enum.count(results) + offset
  end

  defp last(_), do: nil

  defp message(error) do
    if is_exception(error) do
      Exception.message(error)
    else
      inspect(error)
    end
  end

  defp render_middle_page_num(assigns, num, trailing_page_nums) do
    ellipsis? = num in trailing_page_nums || num <= 3

    ~H"""
    <span
      :if={{ show_ellipses?(@data) }}
      class={{
        "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700",
        "bg-gray-300": !ellipsis?
      }}
    >
      <span :if={{ ellipsis? }}>
        ...
      </span>
      <span :if={{ !ellipsis? }}>
        {{ num }}
      </span>
    </span>
    """
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
      max(page_nums - 2, 4)..page_nums
    else
      []
    end
  end

  defp data({:ok, data}), do: data(data)
  defp data({:error, _}), do: []
  defp data(%Ash.Page.Offset{results: results}), do: results
  defp data(%Ash.Page.Keyset{results: results}), do: results
  defp data(data), do: data

  defp offset?({:ok, data}), do: offset?(data)
  defp offset?(%Ash.Page.Offset{}), do: true
  defp offset?(_), do: false

  defp keyset?({:ok, data}), do: keyset?(data)
  defp keyset?(%Ash.Page.Keyset{}), do: true
  defp keyset?(_), do: false

  defp count({:ok, %{count: count}}), do: count
  defp count(%{count: count}), do: count
  defp count(_), do: nil
end
