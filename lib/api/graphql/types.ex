defmodule Api.GraphQL.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation
  use Absinthe.Ecto, repo: Api.Repo

  alias Api.Repo
  alias Api.Accounts.User

  import_types Absinthe.Type.Custom
  import_types Api.GraphQL.Scalars
  import_types Api.GraphQL.InputTypes

  connection node_type: :competition
  object :competition do
    field :id, :string
    field :name, :string
    field :status, :string

    field :teams, list_of(:team)
  end

  object :membership do
    field :user_id, :string
    field :team_id, :string
    field :role, :string

    field :team, :team, resolve: assoc(:team)
    field :user, :user, resolve: assoc(:user)
  end

  connection node_type: :team
  object :team do
    field :id, :string
    field :name, :string
    field :repo, :json # jsonb in postgres
    field :tie_breaker, :integer
    field :project_name, :string
    field :project_desc, :string
    field :technologies, :array
    field :applied, :boolean

    field :competition, :competition, resolve: assoc(:competition)

    field :memberships, list_of(:membership), resolve: assoc(:memberships)
    field :members, list_of(:user), resolve: assoc(:members)
    field :invites, list_of(:invite), resolve: assoc(:invites)
  end

  connection node_type: :user
  object :user do
    field :id, :string
    field :email, :string
    field :name, :string
    field :birthday, :date
    field :employment_status, :string
    field :company, :string
    field :college, :string
    field :github_handle, :string
    field :twitter_handle, :string
    field :linkedin_url, :string
    field :bio, :string
    field :role, :string
    field :tshirt_size, :string
    field :gravatar_hash, :string do
      resolve fn _args, %{source: source} ->
        {:ok, User.gravatar_hash(source)}
      end
    end
    field :display_name, :string do
      resolve fn _args, %{source: source} ->
        {:ok, User.display_name(source)}
      end
    end

    field :teams, list_of(:team), resolve: assoc(:teams)
    field :invites, list_of(:invite), resolve: assoc(:invites)
    field :invitations, list_of(:invite), resolve: assoc(:invitations)
  end

  connection node_type: :invite
  object :invite do
    field :id, :string
    field :open, :boolean
    field :description, :string
    field :email, :string
    field :display_name, :string do
      resolve fn _args, %{source: source} ->
        {
          :ok,
          User.display_name(
            (source.email && %{name: nil, email: source.email})
            || (source |> Repo.preload(:invitee)).invitee
          )
        }
      end
    end
    field :gravatar_hash, :string do
      resolve fn _args, %{source: source} ->
        {
          :ok,
          User.gravatar_hash(
            (source.email && source)
            || (source |> Repo.preload(:invitee)).invitee
          )
        }
      end
    end

    field :invitee, :user, resolve: assoc(:invitee)
    field :host, :user, resolve: assoc(:host)
    field :team, :user, resolve: assoc(:team)
  end

  connection node_type: :workshop
  object :workshop do
    field :name, :string
    field :slug, :string
    field :summary, :string
    field :description, :string
    field :speaker, :string
    field :participant_limit, :integer
    field :year, :integer
    field :speaker_image, :string
    field :banner_image, :string
    field :short_speaker, :string
    field :short_date, :string
  end

end
