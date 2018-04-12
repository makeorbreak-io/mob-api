defmodule Api.GraphQL.InputTypes do
  use Absinthe.Schema.Notation

  input_object :ai_competition_bot_input do
    field :title, non_null(:string)
    field :sdk, non_null(:string)
    field :source_code, non_null(:string)
  end

  input_object :team_input do
    field :name, non_null(:string)
    field :project_name, :string
    field :project_desc, :string
    field :technologies, :array
    field :applied, :boolean
    field :prize_preference, :string # stringified array
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

  input_object :workshop_input do
    field :slug, non_null(:string)
    field :short_date, non_null(:string)
    field :short_speaker, non_null(:string)
    field :name, non_null(:string)
    field :summary, non_null(:string)
    field :description, non_null(:string)
    field :speaker, non_null(:string)
    field :participant_limit, non_null(:integer)
    field :year, non_null(:integer)
    field :speaker_image, :string
    field :banner_image, :string
  end

  input_object :flyby_input do
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :time, non_null(:integer)
  end

  input_object :suffrage_input do
    field :name, non_null(:string)
    field :slug, non_null(:string)
  end
end
