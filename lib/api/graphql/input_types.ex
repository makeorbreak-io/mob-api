defmodule Api.GraphQL.InputTypes do
  use Absinthe.Schema.Notation

  input_object :team_input do
    field :name, non_null(:string)
    field :project_name, :string
    field :project_desc, :string
    field :technologies, :array
    field :applied, :boolean
  end

  input_object :user_input do
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :birthday, :date
    field :employment_status, :string
    field :company, :string
    field :college, :string
    field :github_handle, :string
    field :twitter_handle, :string
    field :linkedin_url, :string
    field :bio, :string
    field :role, :string
    field :tshirt_size, non_null(:string)
  end
end
