# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

ExUnit.start()
Logger.configure(level: :debug)

Application.ensure_all_started(:os_mon)

children = [
  AshAdmin.Test.Endpoint,
  {Phoenix.PubSub, [name: AshAdmin.Test.PubSub, adapter: Phoenix.PubSub.PG2]}
]

{:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
