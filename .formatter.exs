# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

spark_locals_without_parens = [
  accepted_extensions: 1,
  actor?: 1,
  actor_load: 1,
  create_actions: 1,
  default_resource_page: 1,
  destroy_actions: 1,
  field: 1,
  field: 2,
  format_fields: 1,
  generic_actions: 1,
  label_field: 1,
  max_file_size: 1,
  name: 1,
  polymorphic_actions: 1,
  polymorphic_tables: 1,
  read_actions: 1,
  relationship_display_fields: 1,
  relationship_select_max_items: 1,
  resource_group: 1,
  resource_group_labels: 1,
  show?: 1,
  show_action: 1,
  show_calculations: 1,
  show_resources: 1,
  show_sensitive_fields: 1,
  table_columns: 1,
  type: 1,
  update_actions: 1
]

macro_locals_without_parens = [
  ash_admin: 1,
  ash_admin: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix],
  locals_without_parens: spark_locals_without_parens ++ macro_locals_without_parens,
  plugins: [Phoenix.LiveView.HTMLFormatter],
  export: [
    locals_without_parens: spark_locals_without_parens ++ macro_locals_without_parens
  ]
]
