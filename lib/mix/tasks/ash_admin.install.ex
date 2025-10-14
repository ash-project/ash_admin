# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AshAdmin.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs AshAdmin"
  end

  def example do
    "mix ash_admin.install --example arg"
  end

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshAdmin.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :ash_admin,
        # dependencies to add
        adds_deps: [],
        # dependencies to add and call their associated installers, if they exist
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)

      {igniter, router} =
        Igniter.Libs.Phoenix.select_router(igniter, "Which router should AshAdmin be added to?")

      {igniter, domains} = Ash.Domain.Igniter.list_domains(igniter)

      igniter
      |> Igniter.Project.Formatter.import_dep(:ash_admin)
      |> Spark.Igniter.prepend_to_section_order(:"Ash.Resource", [:admin])
      |> Spark.Igniter.prepend_to_section_order(:"Ash.Domain", [:admin])
      |> add_to_router(app_name, router)
      |> add_admin_to_all_domains(domains)
    end

    defp add_admin_to_all_domains(igniter, domains) do
      Enum.reduce(domains, igniter, fn domain, igniter ->
        igniter
        |> Spark.Igniter.add_extension(domain, Ash.Domain, :extensions, AshAdmin.Domain)
        |> Spark.Igniter.set_option(domain, [:admin, :show?], true)
      end)
    end

    defp add_to_router(igniter, app_name, router) do
      if router do
        Igniter.Project.Module.find_and_update_module!(igniter, router, fn zipper ->
          zipper =
            case Igniter.Code.Common.move_to(
                   zipper,
                   &Igniter.Code.Function.function_call?(&1, :ash_admin, [1, 2])
                 ) do
              :error ->
                Igniter.Code.Common.add_code(
                  zipper,
                  """
                  if Application.compile_env(#{inspect(app_name)}, :dev_routes) do
                    import AshAdmin.Router

                    scope "/admin" do
                      pipe_through :browser

                      ash_admin "/"
                    end
                  end
                  """,
                  placement: :after
                )

              _ ->
                zipper
            end

          {:ok, zipper}
        end)
      else
        Igniter.add_warning(igniter, """
        No Phoenix router found or selected. Please ensure that Phoenix is set up
        and then run this installer again with

            mix igniter.install ash_admin
        """)
      end
    end
  end
else
  defmodule Mix.Tasks.AshAdmin.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'ash_admin.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
