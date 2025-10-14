# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAdmin.Components.TopNav.TenantForm do
  @moduledoc false
  use Phoenix.Component
  import AshAdmin.Helpers

  attr :tenant, :string, required: true
  attr :clear_tenant, :string, required: true
  attr :set_tenant, :string, required: true
  attr :editing_tenant, :boolean, required: true

  def tenant_form(assigns) do
    ~H"""
    <div id="tenant-form" class="relative text-white" phx-hook="Tenant">
      <.form :if={@editing_tenant} for={to_form(%{}, as: :tenant)} phx-submit={@set_tenant}>
        <input
          type="text"
          name="tenant"
          value={@tenant}
          class={classes("text-black": @editing_tenant)}
        />
        <button phx-click="stop_editing_tenant">
          <svg
            width="1em"
            height="1em"
            viewBox="0 0 16 16"
            fill="white"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fill-rule="evenodd"
              d="M14 1H2a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1zM2 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2z"
            />
            <path
              fill-rule="evenodd"
              d="M10.97 4.97a.75.75 0 0 1 1.071 1.05l-3.992 4.99a.75.75 0 0 1-1.08.02L4.324 8.384a.75.75 0 1 1 1.06-1.06l2.094 2.093 3.473-4.425a.236.236 0 0 1 .02-.022z"
            />
          </svg>
        </button>
      </.form>
      <a :if={!@editing_tenant} href="#" phx-click="start_editing_tenant">
        {if @tenant, do: "Tenant: #{@tenant}", else: "No tenant"}
      </a>
      <button :if={@tenant} phx-click={@clear_tenant}>
        <svg
          width="1em"
          height="1em"
          viewBox="0 0 16 16"
          fill="white"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fill-rule="evenodd"
            d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"
          />
          <path
            fill-rule="evenodd"
            d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"
          />
        </svg>
      </button>
    </div>
    """
  end
end
