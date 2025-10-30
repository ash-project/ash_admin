<!--
SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.13.23](https://github.com/ash-project/ash_admin/compare/v0.13.22...v0.13.23) (2025-10-30)




### Bug Fixes:

* don't include nil tables when considering if polymorphic tables is empty by Zach Daniel

## [v0.13.22](https://github.com/ash-project/ash_admin/compare/v0.13.21...v0.13.22) (2025-10-30)




### Bug Fixes:

* don't add the resource's primary table if there are no polymorphic tables by Zach Daniel

## [v0.13.21](https://github.com/ash-project/ash_admin/compare/v0.13.20...v0.13.21) (2025-10-30)




### Bug Fixes:

* include resource's table in polymorphic tables dropdown by Zach Daniel

### Improvements:

* allow gettext ~> 1.0 (#368) by Aleksandr Lossenko

## [v0.13.20](https://github.com/ash-project/ash_admin/compare/v0.13.19...v0.13.20) (2025-10-24)




### Bug Fixes:

* Add __spark_metadata__ field to Field struct (#366) by Jechol Lee

## [v0.13.19](https://github.com/ash-project/ash_admin/compare/v0.13.18...v0.13.19) (2025-09-24)




### Bug Fixes:

* set brand on loading to_one relationships by Zach Daniel

* use tenant when loading to_one relationships by Zach Daniel

### Improvements:

* support `actor_load` option by Zach Daniel

## [v0.13.18](https://github.com/ash-project/ash_admin/compare/v0.13.17...v0.13.18) (2025-08-31)




### Bug Fixes:

* properly retain values for fallback rendered attribute inputs by Zach Daniel

### Improvements:

* inline jsoneditor and easymde for security by Zach Daniel

## [v0.13.17](https://github.com/ash-project/ash_admin/compare/v0.13.16...v0.13.17) (2025-08-21)




### Bug Fixes:

* use `Resource.admin.show_action` (#359) by quartz

## [v0.13.16](https://github.com/ash-project/ash_admin/compare/v0.13.15...v0.13.16) (2025-08-18)




### Bug Fixes:

* handle overflow & tenant form for long domains list by Zach Daniel

## [v0.13.15](https://github.com/ash-project/ash_admin/compare/v0.13.14...v0.13.15) (2025-08-18)




### Bug Fixes:

* better names for version resources by Zach Daniel

* Read phoenix js assests at compile time (#355) by Kenneth Kostrešević

### Improvements:

* add a little razzle dazzle to the authorizing/actor buttons (#352) by Andy LeClair

* change svg icons to words (#351) by Andy LeClair

## [v0.13.14](https://github.com/ash-project/ash_admin/compare/v0.13.13...v0.13.14) (2025-08-07)




### Bug Fixes:

* better names for version resources by Zach Daniel

* Read phoenix js assests at compile time (#355) by Kenneth Kostrešević

### Improvements:

* add a little razzle dazzle to the authorizing/actor buttons (#352) by Andy LeClair

* change svg icons to words (#351) by Andy LeClair

## [v0.13.13](https://github.com/ash-project/ash_admin/compare/v0.13.12...v0.13.13) (2025-07-29)




### Bug Fixes:

* Add `ash_admin: 2` in locals_without_parens (#348) by kik4444

## [v0.13.12](https://github.com/ash-project/ash_admin/compare/v0.13.11...v0.13.12) (2025-07-17)




### Bug Fixes:

* properly only show dropdowns on related resources by Zach Daniel

### Improvements:

* support liveview 1.1-rc by Zach Daniel

## [v0.13.11](https://github.com/ash-project/ash_admin/compare/v0.13.10...v0.13.11) (2025-07-02)




### Bug Fixes:

* Prevent double HTML escaping (#332) by Jechol Lee

* Encode/decode cookie values in JS (#328) by Jechol Lee

## [v0.13.10](https://github.com/ash-project/ash_admin/compare/v0.13.9...v0.13.10) (2025-06-18)




### Improvements:

* Change level of repetitive log (#324) by capoccias

## [v0.13.9](https://github.com/ash-project/ash_admin/compare/v0.13.8...v0.13.9) (2025-06-06)




### Bug Fixes:

* don't use access protocol on structs by Zach Daniel

## [v0.13.8](https://github.com/ash-project/ash_admin/compare/v0.13.7...v0.13.8) (2025-06-06)




### Bug Fixes:

* handle case where no uploads are present by Zach Daniel

## [v0.13.7](https://github.com/ash-project/ash_admin/compare/v0.13.6...v0.13.7) (2025-06-04)




### Bug Fixes:

* allow uploads in nested forms

* lookup and consume upload entries correctly

* Handle cross-domain links (#314)

* Handle cross-domain links

### Improvements:

* add upload options for `Ash.Type.File` arguments (#316)

## [v0.13.6](https://github.com/ash-project/ash_admin/compare/v0.13.5...v0.13.6) (2025-06-01)




### Bug Fixes:

* various mistakes in union type handling

* don't assume `form.source.type` is set

* Handle cross-domain links

## [v0.13.5](https://github.com/ash-project/ash_admin/compare/v0.13.4...v0.13.5) (2025-05-20)




### Bug Fixes:

* don't duplicate `ash_admin` routes on installation

## [v0.13.4](https://github.com/ash-project/ash_admin/compare/v0.13.3...v0.13.4) (2025-04-09)




### Bug Fixes:

* don't display union type field for `nil` values

## [v0.13.3](https://github.com/ash-project/ash_admin/compare/v0.13.2...v0.13.3) (2025-03-18)




### Bug Fixes:

* use actor, authorize? and tenant from context for relationship field

## [v0.13.2](https://github.com/ash-project/ash_admin/compare/v0.13.1...v0.13.2) (2025-03-05)




### Bug Fixes:

* show show_page properly

## [v0.13.1](https://github.com/ash-project/ash_admin/compare/v0.13.0...v0.13.1) (2025-02-22)




### Bug Fixes:

* use AbortSignal in Typeahead hook to remove up event listeners

### Improvements:

* Search max items default (#274)

## [v0.13.0](https://github.com/ash-project/ash_admin/compare/v0.12.6...v0.13.0) (2025-02-17)




### Features:

* Select/Typeahead for related items using `label_field` (#222)

## [v0.12.6](https://github.com/ash-project/ash_admin/compare/v0.12.5...v0.12.6) (2025-01-13)




### Bug Fixes:

* guard against problematic primary read action configurations (#255) (#256)

### Improvements:

* add installer

## [v0.12.5](https://github.com/ash-project/ash_admin/compare/v0.12.4...v0.12.5) (2025-01-06)




### Bug Fixes:

* use configured actions for determining update/destroy links

## [v0.12.4](https://github.com/ash-project/ash_admin/compare/v0.12.3...v0.12.4) (2025-01-03)




### Bug Fixes:

* UnsuedParams: Filter nil values (#248)

* UnusedParams: handle nil params (#247)

* PhoenixLiveView: remove phx-feedback-for and fix unsued params (#244)

## [v0.12.3](https://github.com/ash-project/ash_admin/compare/v0.12.2...v0.12.3) (2024-12-19)




### Bug Fixes:

* dont show all calculations by default

* Calculations: Show form when calculation doesn't have arguments (#241)

## [v0.12.2](https://github.com/ash-project/ash_admin/compare/v0.12.1...v0.12.2) (2024-12-17)




### Bug Fixes:

* use pagination if the action supports it

## [v0.12.1](https://github.com/ash-project/ash_admin/compare/v0.12.0...v0.12.1) (2024-12-17)




### Bug Fixes:

* various fixes for new loadable calculation forms

* handling of simple union types in arrays of union types (#240)

* duplicate element ids in form for union arrays

* fix form handling of "simple" union type (#220) (#238)

## [v0.12.0](https://github.com/ash-project/ash_admin/compare/v0.11.11...v0.12.0) (2024-12-12)

### Features:

- Calculations: Able to show calculations on show page (#235)

- Format date/time fields also in Show and Update pages (#229)

### Improvements:

- Sort resource_group_labels by given order (#225)

## [v0.11.11](https://github.com/ash-project/ash_admin/compare/v0.11.10...v0.11.11) (2024-10-30)

### Bug Fixes:

- properly update any kind of form data

- fix relationship loading on Resource Update form (#220) (#221)

## [v0.11.10](https://github.com/ash-project/ash_admin/compare/v0.11.9...v0.11.10) (2024-10-29)

### Bug Fixes:

- various fixes for unions & form mutations

## [v0.11.9](https://github.com/ash-project/ash_admin/compare/v0.11.8...v0.11.9) (2024-10-17)

### Improvements:

- make generic actions list properly configurable

## [v0.11.8](https://github.com/ash-project/ash_admin/compare/v0.11.7...v0.11.8) (2024-10-17)

### Bug Fixes:

- clean up remaining generic action necessities

## [v0.11.7](https://github.com/ash-project/ash_admin/compare/v0.11.6...v0.11.7) (2024-10-17)

### Improvements:

- support for generic actions

## [v0.11.6](https://github.com/ash-project/ash_admin/compare/v0.11.5...v0.11.6) (2024-09-19)

### Bug Fixes:

- properly handle nested union form types by cleaning/massaging them

## [v0.11.5](https://github.com/ash-project/ash_admin/compare/v0.11.4...v0.11.5) (2024-08-26)

### Improvements:

- remove tails

## [v0.11.4](https://github.com/ash-project/ash_admin/compare/v0.11.3...v0.11.4) (2024-08-01)

### Bug Fixes:

- properly support adding embeds for nil values

- upgrade `ash_phoenix` for fix on calculating values

- use resource's configured domain before default domain

- ensure `actor_tenant` is always set

- ensure table columsn are loaded, bypassing (as yet) unknown bug

### Improvements:

- don't log forbidden errors

## [v0.11.3](https://github.com/ash-project/ash_admin/compare/v0.11.2...v0.11.3) (2024-06-25)

### Bug Fixes:

- don't go to potentially non-existant create actions

## [v0.11.2](https://github.com/ash-project/ash_admin/compare/v0.11.1...v0.11.2) (2024-06-25)

### Bug Fixes:

- properly render errors data table forms

- update to support 0.20 (#179)

## [v0.11.1](https://github.com/ash-project/ash_admin/compare/v0.11.0...v0.11.1) (2024-06-13)

### Bug Fixes:

- properly support lists of embeds

- render relationship inputs even when type is not a map

- properly render tenant form on mobile sidebar

### Improvements:

- various fixes around unions

- support for unions

## [v0.11.0](https://github.com/ash-project/ash_admin/compare/v0.10.10-rc.1...v0.11.0) (2024-05-10)

### Bug Fixes:

- TopNav when in mobile view (size < md) (#128)

- properly accept private attributes in admin

- clear actor_tenant cookie when clearing actor (#101)

- small refactor in actor plug (#99)

### Improvements:

- track actor tenant, use it for fetching actor

## [v0.10.10-rc.1](https://github.com/ash-project/ash_admin/compare/v0.10.10-rc.0...v0.10.10-rc.1) (2024-04-03)

### Bug Fixes:

- get checks passing, fix various bugs

- loading multiple relationships with the same destination resource that has sensitive fields (#98)

## [v0.10.10-rc.0](https://github.com/ash-project/ash_admin/compare/v0.10.9...v0.10.10-rc.0) (2024-04-02)

### Bug Fixes:

- properly add indexes to embedded list attribtues

- ensure action selection is accurate/consistent

- only consider top-level targets for input pruning

- only show forms for map type inputs

### Improvements:

- upgrade to 3.0

## [v0.10.9](https://github.com/ash-project/ash_admin/compare/v0.10.8...v0.10.9) (2024-03-29)

### Bug Fixes:

- only show forms for map type inputs

### Improvements:

- upgrade to 3.0

## [v0.10.8](https://github.com/ash-project/ash_admin/compare/v0.10.7...v0.10.8) (2024-03-19)

### Bug Fixes:

- missing handle event in read forms

- Allow blank/nil default values in :atom inputs when allow_nil? is true (#93)

- Allow blank/default default values in :atom inputs when allow_nil? is true

### Improvements:

- Add :csp_nonce_assign_key to ash_admin options (fix for /issues/91) (#92)

## [v0.10.7](https://github.com/ash-project/ash_admin/compare/v0.10.6...v0.10.7) (2024-02-26)

### Bug Fixes:

- properly prevent access to actions not configured to be in the UI

## [v0.10.6](https://github.com/ash-project/ash_admin/compare/v0.10.5...v0.10.6) (2024-02-20)

### Bug Fixes:

- fix lists of values in deeply nested embeds

## [v0.10.5](https://github.com/ash-project/ash_admin/compare/v0.10.4...v0.10.5) (2024-02-11)

### Improvements:

- show internal errors in ash_admin form

## [v0.10.4](https://github.com/ash-project/ash_admin/compare/v0.10.3...v0.10.4) (2024-02-04)

### Improvements:

- fix large gap in header in safari

## [v0.10.3](https://github.com/ash-project/ash_admin/compare/v0.10.2...v0.10.3) (2024-02-04)

### Bug Fixes:

- ensure starting state of dropdowns is honored

### Improvements:

- update to phoenix_html 4.0

- support any sensitive value

- support PhoenixHTML 4.0

- Adds show_sensitive_fields option to Resource to allow unredacting seâ¦ (#86)

## [v0.10.2](https://github.com/ash-project/ash_admin/compare/v0.10.1...v0.10.2) (2024-01-04)

### Bug Fixes:

- ensure tenant stays set after navigating from page

## [v0.10.1](https://github.com/ash-project/ash_admin/compare/v0.10.0...v0.10.1) (2023-12-27)

### Bug Fixes:

- don't hide fields required for managing relationships

- pass tenant to `Changeset.for_*` directly (#84)

## [v0.10.0](https://github.com/ash-project/ash_admin/compare/v0.9.8...v0.10.0) (2023-11-30)

### Features:

- Hide sensitive attributes by default (#82)

### Bug Fixes:

- fix cases where data may not match expected patterns

- allow nil values for all dropdowns to handle list behavior

- Dropdown component has Surface hangover (#81)

### Improvements:

- use prompt instead of adding a nil option for dropdowns

- only ensure `nil` value is present on dropdowns when inside of lists

- fix warnings on actor plug

- use the first enum value as the default for dropdowns

## [v0.9.8](https://github.com/ash-project/ash_admin/compare/v0.9.7...v0.9.8) (2023-11-17)

### Bug Fixes:

- default table_columns to all attributes for proper selecting

## [v0.9.7](https://github.com/ash-project/ash_admin/compare/v0.9.6...v0.9.7) (2023-11-16)

### Bug Fixes:

- properly match on errored loads

## [v0.9.6](https://github.com/ash-project/ash_admin/compare/v0.9.5...v0.9.6) (2023-11-15)

### Bug Fixes:

- Fix JS syntax error and compile latest version of `app.js` (#77)

- don't use nil as new {:array, type} value (#76)

- load each to_one relationship independently and ignore it if it errors

- allow showing false values for boolean selects (#74)

- pass actor when fetching relationships attributes (#73)

- properly provide `arguments` to read actions

### Improvements:

- support calculations & aggregates in table columns

## [v0.9.5](https://github.com/ash-project/ash_admin/compare/v0.9.4...v0.9.5) (2023-10-11)

### Improvements:

- force submit forms

## [v0.9.4](https://github.com/ash-project/ash_admin/compare/v0.9.3...v0.9.4) (2023-08-04)

### Bug Fixes:

- properly reassign form on update

## [v0.9.3](https://github.com/ash-project/ash_admin/compare/v0.9.2...v0.9.3) (2023-08-02)

### Bug Fixes:

- support cross-api relationships in show links

- use `push_patch` instead of `push_redirect`

### Improvements:

- Ui consistency (#62)

## [v0.9.2](https://github.com/ash-project/ash_admin/compare/v0.9.1...v0.9.2) (2023-08-02)

### Bug Fixes:

- fix links to show related resources

## [v0.9.1](https://github.com/ash-project/ash_admin/compare/v0.9.0...v0.9.1) (2023-08-02)

### Bug Fixes:

- use connect params for persisted state

- properly persist cookies

- create-form: errors from removal of surface (#60)

- properly detect update and destroy actions

- revalidate with params on submit

- send set tenant to parent liveview

- set phx-target

- set phx-target on tenant form

- fix editing_tenant in top_nav

### Improvements:

- loosen tails dependency

## [v0.9.0](https://github.com/ash-project/ash_admin/compare/v0.8.2...v0.9.0) (2023-07-28)

### Features:

- Add seed with Admin, User, Customer, Organization and Ticket (#56)

### Bug Fixes:

- set assigns for show block

- fix behaviour and support on_mount and session

### Improvements:

- style the metadata tables consistently (#54)

- remove surface

- support setting an actor

## [v0.8.2](https://github.com/ash-project/ash_admin/compare/v0.8.1...v0.8.2) (2023-07-25)

### Bug Fixes:

- don't show create button if no create actions are configured

- use `authorize?: false` when reading actor from session

### Improvements:

- show all errors on form submit

- Improve frontend a little bit (#52)

- Use overflow-auto instead of overflow-scroll on table

## [v0.8.1](https://github.com/ash-project/ash_admin/compare/v0.8.0...v0.8.1) (2023-04-22)

### Bug Fixes:

- don't authorize actor read

- Admin links are not aware of the scope where ash_admin is called (#49)

- handle cases where actions of a given type don't exist

### Improvements:

- Update Surface to 0.10.0 (#50)

## [v0.8.0](https://github.com/ash-project/ash_admin/compare/v0.7.1...v0.8.0) (2023-03-01)

### Features:

- Inline style nonce (#42)

- Specify nonces on inline styles/JavaScript so they can be allowed by CSPs

### Bug Fixes:

- Add missing mix.lock changes (#43)

- Add missing mix.lock changes

## [v0.7.1](https://github.com/ash-project/ash_admin/compare/v0.7.0...v0.7.1) (2022-11-01)

### Bug Fixes:

- fix markdown editor and make things cleaner

## [v0.7.0](https://github.com/ash-project/ash_admin/compare/v0.6.2...v0.7.0) (2022-10-31)

### Features:

- add markdown attributes

### Improvements:

- add markdown editor

## [v0.6.2](https://github.com/ash-project/ash_admin/compare/v0.6.1...v0.6.2) (2022-10-20)

### Bug Fixes:

- handle missing api/resource better

- if pagination is available but not required, opt to use it

## [v0.6.1](https://github.com/ash-project/ash_admin/compare/v0.6.0-rc.2...v0.6.1) (2022-10-20)

### Improvements:

- update to latest ash

## [v0.6.0-rc.2](https://github.com/ash-project/ash_admin/compare/v0.6.0-rc.1...v0.6.0-rc.2) (2022-09-28)

### Improvements:

- update to latest ash

- unlock unused deps

- support latest ash_phoenix

- update to latest ash

## [v0.6.0-rc.1](https://github.com/ash-project/ash_admin/compare/v0.6.0-rc.0...v0.6.0-rc.1) (2022-09-15)

### Bug Fixes:

- don't call into ash_postgres for tables anymore

- properly match on `Code.ensure_compiled/1` output

### Improvements:

- update to the latest ash

## [v0.5.2](https://github.com/ash-project/ash_admin/compare/v0.5.1-rc.0...v0.5.2) (2022-08-22)

### Improvements:

- update to latest ash

- support value-backed nested forms

## [v0.5.1-rc.0](https://github.com/ash-project/ash_admin/compare/v0.5.0...v0.5.1-rc.0) (2022-08-15)

### Bug Fixes:

- remove unnecessary code

- fix data loading, change tracking (handled by AshPhoenix.Form)

- changelog URL in release tweet (#24)

## [v0.5.0](https://github.com/ash-project/ash_admin/compare/v0.4.5-rc.0...v0.5.0) (2022-08-10)

### Features:

- allow setting primary read action as default resource page (#19)

### Bug Fixes:

- failing error case for nested forms (#21)

### Improvements:

- use new authorize? configuration

## [v0.4.5-rc.0](https://github.com/ash-project/ash_admin/compare/v0.4.4...v0.4.5-rc.0) (2022-05-23)

### Bug Fixes:

- update to latest ash for bugfix

- get the original value using `AshPhoenix.Form.value/2`

### Improvements:

- Top nav resource grouping (#15)

- update ash version and fix build

- add DateInput for dates

## [v0.4.4](https://github.com/ash-project/ash_admin/compare/v0.4.3...v0.4.4) (2022-03-17)

### Bug Fixes:

- don't depend on an rc version

## [v0.4.3](https://github.com/ash-project/ash_admin/compare/v0.4.2...v0.4.3) (2022-03-17)

### Bug Fixes:

- a bunch of behavior fixes, getting the demo to snuff with new Ash

- fix tenant/actor session w/ new phx version

### Improvements:

- update tons of dependencies

## [v0.4.2](https://github.com/ash-project/ash_admin/compare/v0.4.1...v0.4.2) (2022-03-17)

### Bug Fixes:

- a bunch of behavior fixes, getting the demo to snuff with new Ash

- fix tenant/actor session w/ new phx version

### Improvements:

- update tons of dependencies

## [v0.4.2](https://github.com/ash-project/ash_admin/compare/v0.4.1...v0.4.2) (2022-03-17)

### Bug Fixes:

- don't lock phoenix version

## [v0.4.1](https://github.com/ash-project/ash_admin/compare/v0.4.0...v0.4.1) (2022-03-17)

### Bug Fixes:

- various other fixes for events and hooks

- fix issues w/ admin UI not rendering

## [v0.4.0](https://github.com/ash-project/ash_admin/compare/v0.3.0-rc.0...v0.4.0) (2021-11-14)

### Bug Fixes:

- handle new liveview arg pattern

## [v0.3.0-rc.0](https://github.com/ash-project/ash_admin/compare/v0.2.22...v0.3.0-rc.0) (2021-09-01)

### Breaking Changes:

- support latest surface/phoenix

### Improvements:

- remove compile-time router, use params instead

## [v0.2.22](https://github.com/ash-project/ash_admin/compare/v0.2.21...v0.2.22) (2021-07-24)

### Bug Fixes:

- render values properly when no format set

## [v0.2.21](https://github.com/ash-project/ash_admin/compare/v0.2.20...v0.2.21) (2021-07-24)

### Improvements:

- define custom formats for any field (#7)

## [v0.2.20](https://github.com/ash-project/ash_admin/compare/v0.2.19...v0.2.20) (2021-07-23)

### Improvements:

- relationships in datatable (#6)

## [v0.2.19](https://github.com/ash-project/ash_admin/compare/v0.2.18...v0.2.19) (2021-07-23)

### Improvements:

- update to latest ash

## [v0.2.18](https://github.com/ash-project/ash_admin/compare/v0.2.17...v0.2.18) (2021-07-20)

### Bug Fixes:

- digest assets

- show proper values in update forms on initial render

## [v0.2.17](https://github.com/ash-project/ash_admin/compare/v0.2.16-rc.1...v0.2.17) (2021-07-20)

### Improvements:

- add json editor

## [v0.2.16-rc.1](https://github.com/ash-project/ash_admin/compare/v0.2.16-rc.0...v0.2.16-rc.1) (2021-07-18)

### Improvements:

- update to latest ash

## [v0.2.16-rc.0](https://github.com/ash-project/ash_admin/compare/v0.2.15...v0.2.16-rc.0) (2021-07-18)

### Bug Fixes:

- show boolean default values better

### Improvements:

- update to new form logic

## [v0.2.15](https://github.com/ash-project/ash_admin/compare/v0.2.14...v0.2.15) (2021-05-18)

### Bug Fixes:

- retain `manage_relationship_source` context where possible

## [v0.2.14](https://github.com/ash-project/ash_admin/compare/v0.2.13...v0.2.14) (2021-05-14)

### Improvements:

- general manage relationship improvements

## [v0.2.13](https://github.com/ash-project/ash_admin/compare/v0.2.12...v0.2.13) (2021-05-13)

### Bug Fixes:

- track pkey of embeds when adding

## [v0.2.12](https://github.com/ash-project/ash_admin/compare/v0.2.11...v0.2.12) (2021-05-10)

### Improvements:

- support explicit enum types

## [v0.2.11](https://github.com/ash-project/ash_admin/compare/v0.2.10...v0.2.11) (2021-05-06)

### Bug Fixes:

- fix special text fields

### Improvements:

- always show action dropdown

- log on failures in the UI

## [v0.2.10](https://github.com/ash-project/ash_admin/compare/v0.2.9...v0.2.10) (2021-04-17)

### Bug Fixes:

- update to ash_phoenix, fix relationship embeds

## [v0.2.9](https://github.com/ash-project/ash_admin/compare/v0.2.8...v0.2.9) (2021-04-16)

### Improvements:

- support array attribute/arguments properly

## [v0.2.8](https://github.com/ash-project/ash_admin/compare/v0.2.7...v0.2.8) (2021-04-15)

### Bug Fixes:

- properly track embedded attribute targets

## [v0.2.7](https://github.com/ash-project/ash_admin/compare/v0.2.6...v0.2.7) (2021-04-09)

### Bug Fixes:

- set actor in datatable

## [v0.2.6](https://github.com/ash-project/ash_admin/compare/v0.2.5...v0.2.6) (2021-04-09)

### Bug Fixes:

- support binary data (by not showing it)

## [v0.2.5](https://github.com/ash-project/ash_admin/compare/v0.2.4...v0.2.5) (2021-03-30)

### Bug Fixes:

- don't send empty params on save

### Improvements:

- update to latest ash_phoenix

## [v0.2.4](https://github.com/ash-project/ash_admin/compare/v0.2.3...v0.2.4) (2021-03-30)

### Bug Fixes:

- show add button on array input relationships

## [v0.2.3](https://github.com/ash-project/ash_admin/compare/v0.2.2...v0.2.3) (2021-03-29)

### Bug Fixes:

- remove path dependency on ash

## [v0.2.2](https://github.com/ash-project/ash_admin/compare/v0.2.1...v0.2.2) (2021-03-29)

### Bug Fixes:

- allow removing to_one relationships on creates

### Improvements:

- support lookup forms _or_ create forms

## [v0.2.1](https://github.com/ash-project/ash_admin/compare/v0.2.0...v0.2.1) (2021-03-28)

### Bug Fixes:

- update ash_admin dependency

## [v0.2.0](https://github.com/ash-project/ash_admin/compare/v0.1.6...v0.2.0) (2021-03-28)

### Features:

- more testing resources + relationship argument forms!

## [v0.1.6](https://github.com/ash-project/ash_admin/compare/v0.1.5...v0.1.6) (2021-03-25)

### Improvements:

- use new relationship management logic

## [v0.1.5](https://github.com/ash-project/ash_admin/compare/v0.1.4...v0.1.5) (2021-03-24)

### Bug Fixes:

- remove inspect

- properly only provide changing fields to actions

## [v0.1.4](https://github.com/ash-project/ash_admin/compare/v0.1.3...v0.1.4) (2021-03-24)

### Bug Fixes:

- support tenant on read actions

- remove inspect

### Improvements:

- only send changing fields

- don't show `destination_field` on related tables

## [v0.1.3](https://github.com/ash-project/ash_admin/compare/v0.1.2...v0.1.3) (2021-03-23)

### Bug Fixes:

- use version properly

## [v0.1.2](https://github.com/ash-project/ash_admin/compare/v0.1.1...v0.1.2) (2021-03-22)

### Bug Fixes:

- fix build

## [v0.1.1](https://github.com/ash-project/ash_admin/compare/v0.1.0...v0.1.1) (2021-03-22)

### Bug Fixes:

- use static routes

## [v0.1.0](https://github.com/ash-project/ash_admin/compare/v0.1.0...v0.1.0) (2021-03-22)

### Features:

- draw the rest of the owl

- support fully managed relationships

- set actor from show page

- support destroy actions

- lots of new features, including related id updates

### Bug Fixes:

- various fixes

- various fixes/improvements

- various bug fixes

- update dep versions

- fix action changing

### Improvements:

- general fixes, configurable action lists

- add pagination support

- support read actions with arguments

- add "log in" button
