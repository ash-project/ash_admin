# Contributing to AshAdmin

AshAdmin includes a development app, located in the `dev` folder, so you don't need to have an external Phoenix app to plug AshAdmin into.

You'll need to have PostgreSQL set up locally. Then you can run:

* `mix ash_postgres.create`
* `mix migrate`
* `mix migrate_tenants`
* `mix setup`

Then, you can start the app server with: `mix dev`

If you make changes to the dev resources, you can generate migrations with `mix generate_migrations`

If you make changes to any of the assets (CSS or JavaScript), including updating dependencies that include assets such as Phoenix LiveView, you will need to recompile the assets with `mix assets.deploy`.

For general Ash contribution details, check out [our contribution guide](`e:ash:contributing-to-ash.md`).
