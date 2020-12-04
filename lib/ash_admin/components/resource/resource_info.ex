defmodule AshAdmin.Components.Resource.Info do
  use Surface.Component

  import AshAdmin.Helpers
  alias Surface.Components.LiveRedirect

  prop resource, :any, required: true
  prop api, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <div class="col-5">
          <div class="page-header">
            <h1>Public Attributes</h1>
          </div>
          <table class="table">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Type</th>
                <th scope="col">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{attribute <- Ash.Resource.public_attributes(@resource)}}>
              <th scope="row"> {{attribute.name}} </th>
              <td> {{attribute_type(attribute)}} </td>
              <td> {{attribute.description}}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="col-2"></div>
        <div class="col-5">
          <div class="page-header">
            <h1>Public Relationships</h1>
          </div>
          <table class="table">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Type</th>
                <th scope="col">Destination</th>
                <th scope="col">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{relationship <- Ash.Resource.public_relationships(@resource)}}>
                <th scope="row"> {{relationship.name}}</th>
                <td> {{relationship.type}}</td>
                <td>
                  <LiveRedirect to={{ash_admin_path(@socket, @api, relationship.destination)}}>
                    {{AshAdmin.Resource.name(relationship.destination)}}
                  </LiveRedirect>
                </td>
                <td> {{relationship.description}}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div class="row">
        <div class="col-5">
          <div class="page-header">
            <h1>Private Attributes</h1>
          </div>
          <table class="table">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Type</th>
                <th scope="col">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr :for= {{%{private?: true} = attribute <- Ash.Resource.attributes(@resource)}}>
                <th scope="row"> {{attribute.name}}</th>
                <td> {{attribute_type(attribute)}}</td>
                <td> {{attribute.description}}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="col-2"></div>
        <div class="col-5">
          <div class="page-header">
            <h1>Private Relationships</h1>
          </div>
          <table class="table">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Type</th>
                <th scope="col">Destination</th>
                <th scope="col">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr :for= {{%{private?: true} = relationship <- Ash.Resource.relationships(@resource)}}>
                <th scope="row"> {{relationship.name}}</th>
                <td>{{relationship.type}}</td>
                <td>
                  <LiveRedirect to={{ash_admin_path(@socket, @api, relationship.destination)}}>
                    {{AshAdmin.Resource.name(relationship.destination)}}
                  </LiveRedirect>
                </td>
                <td> {{relationship.description}}</td>
              </tr>
            </tbody>
          </table>
      </div>
      </div>
    </div>
    """
  end

  defp attribute_type(attribute) do
    case attribute.type do
      {:array, type} ->
        "list of " <> String.trim_leading(inspect(type), "Ash.Type.")

      type ->
        String.trim_leading(inspect(type), "Ash.Type.")
    end
  end
end
