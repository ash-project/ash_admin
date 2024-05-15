spark_locals_without_parens = [
  actor?: 1,
  create_actions: 1,
  default_resource_page: 1,
  destroy_actions: 1,
  field: 1,
  field: 2,
  format_fields: 1,
  name: 1,
  polymorphic_actions: 1,
  polymorphic_tables: 1,
  read_actions: 1,
  relationship_display_fields: 1,
  resource_group: 1,
  resource_group_labels: 1,
  show?: 1,
  show_action: 1,
  show_resources: 1,
  show_sensitive_fields: 1,
  table_columns: 1,
  type: 1,
  update_actions: 1
]

macro_locals_without_parens = [
  ash_admin: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix, :phoenix_html],
  locals_without_parens: spark_locals_without_parens ++ macro_locals_without_parens,
  plugins: [Phoenix.LiveView.HTMLFormatter],
  export: [
    locals_without_parens: spark_locals_without_parens ++ macro_locals_without_parens
  ]
]
