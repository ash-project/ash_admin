# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

[
  ## all available options with default values (see `mix check` docs for description)
  # parallel: true,
  # skipped: true,

  ## list of tools (see `mix check` docs for defaults)
  tools: [
    ## curated tools may be disabled (e.g. the check for compilation warnings)
    # {:compiler, false},
    {:npm_test, false},
    {:gettext, false},
    {:check_formatter, command: "mix spark.formatter --check"},
    {:reuse, command: ["pipx", "run", "reuse", "lint", "-q"]}

    ## ...or adjusted (e.g. use one-line formatter for more compact credo output)
    # {:credo, "mix credo --format oneline"},
    ## custom new tools may be added (mix tasks or arbitrary commands)
    # {:my_mix_task, command: "mix release", env: %{"MIX_ENV" => "prod"}},
    # {:my_arbitrary_tool, command: "npm test", cd: "assets"},
    # {:my_arbitrary_script, command: ["my_script", "argument with spaces"], cd: "scripts"}
  ]
]
