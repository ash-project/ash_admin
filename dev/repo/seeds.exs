defmodule Demo.Seeder do
  require Ash.Query
  alias Ash.Seed
  alias Demo.Accounts.User
  alias Demo.Tickets.{Customer, Organization, Representative, Ticket}

  @spec insert_admin!(String.t(), String.t()) :: User.t()
  def insert_admin!(first_name, last_name) do
    Seed.seed!(User, %{
      first_name: first_name,
      last_name: last_name,
      admin: true
    })
  end

  @spec insert_user!(String.t(), String.t(), String.t(), String.t(), String.t()) :: User.t()
  def insert_user!(first_name, last_name, bio, history, api_key) do
    Seed.seed!(User, %{
      first_name: first_name,
      last_name: last_name,
      profile: %{
        bio: bio,
        history: history,
      },
      api_key: api_key,
      alternate_profiles: []
    })
  end

  @spec insert_customer!(String.t(), String.t()) :: Customer.t()
  def insert_customer!(first_name, last_name) do
    Seed.seed!(Customer, %{
      first_name: first_name,
      last_name: last_name,
      representative: false
    })
  end

   @spec insert_representative!(String.t(), String.t(), Organization.t()) :: Representative.t()
  def insert_representative!(first_name, last_name, organization \\ nil) do
    Seed.seed!(Representative, %{
      first_name: first_name,
      last_name: last_name,
      representative: true,
      organization_id: organization && organization.id
    })
  end

  @spec insert_organization!(String.t()) :: Organization.t()
  def insert_organization!(name) do
    Seed.seed!(Organization, %{name: name});
  end

  @spec insert_ticket!(String.t(), String.t(), Customer.t(), Representative.t(), Organization.t()) :: Ticket.t()
  def insert_ticket!(subject, description, reporter, representative, organization) do
    Seed.seed!(Ticket, %{
      subject: subject,
      description: description,
      reporter_id: reporter.id,
      representative_id: representative.id,
      organization_id: organization.id,
      comments: []
    })
  end

  def arguments("--truncate") do
    [Ticket, Organization, User]
    |> Enum.map(&truncate/1)
  end

  defp truncate(resource) do
    resource
    |> Ash.Query.new()
    |> Ash.Query.data_layer_query()
    |> case do
      {:ok, query} -> Demo.Repo.delete_all(query)
    end
  end

end

Supervisor.start_link([Demo.Repo], strategy: :one_for_one)

System.argv()
|> Enum.each(&Demo.Seeder.arguments/1)

Demo.Seeder.insert_admin!("Super", "Admin");
org = Demo.Seeder.insert_organization!("Ash Project");
Demo.Seeder.insert_user!("Alice", "Courtney", "Lorem ipsum dolor sit amet", "Duis aute irure dolor in reprehenderit in voluptate velit esse", "123456");
bob = Demo.Seeder.insert_customer!("Bob", "Maclean");
carol = Demo.Seeder.insert_representative!("Carol", "White", org);
rasha = Demo.Seeder.insert_representative!("Rasha", "Khan");

Demo.Seeder.insert_ticket!("Lorem ipsum", "Duis aute irure dolor in reprehenderit in voluptate", bob, carol, org);
