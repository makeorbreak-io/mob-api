defmodule Api.GraphQL.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  use Absinthe.Ecto, repo: Api.Repo

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.AICompetition.Bots

  import_types Absinthe.Type.Custom
  import_types Api.GraphQL.Scalars
  import_types Api.GraphQL.InputTypes

  connection node_type: :ai_competition_game
  object :ai_competition_game do
    field :id, :string
    field :initial_state, :json
    field :final_state, :json
    field :status, :string
    field :is_ranked, :boolean
    field :run, :string
    field :inserted_at, :utc_datetime
    field :updated_at, :utc_datetime

    # field :game_bots, :ai_competition_game_bot, resolve: assoc(:game_bots)
    field :bots, list_of(:ai_competition_bot), resolve: assoc(:bots)
    # field :users, :user, resolve: assoc(:users)
  end

  # connection node_type: :ai_competition_game_bot
  # object :ai_competition_game_bot do
  #   field :id, :string
  #   field :score, :integer

  #   field :bot, :ai_competition_bot, resolve: assoc(:bot)
  # end

  connection node_type: :ai_competition_bot
  object :ai_competition_bot do
    field :id, :string
    field :sdk, :string
    field :status, :string
    field :title, :string
    field :compilation_output, :string
    field :revision, :integer
    field :inserted_at, :utc_datetime

    field :author, :json do
      resolve fn _args, %{source: source} ->
        user = Repo.preload(source, :user).user
        {:ok, %{
          name: User.display_name(user),
          id: user.id,
        }}
      end
    end

    # source code can only be shown to their respective authors
    field :source_code, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if source.user_id == current_user.id do
          {:ok, source.source_code}
        else
          {:ok, nil}
        end
      end
    end

    # field :user, :user, resolve: assoc(:user)
    # field :game_bots, :ai_competition_game_bot, resolve: assoc(:game_bots)
  end

  connection node_type: :competition
  object :competition do
    field :id, :string
    field :name, :string
    field :status, :string

    field :teams, list_of(:team)
  end

  object :medium do
    field :posts, :json
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
    # field :technologies, :array
    field :applied, :boolean
    field :accepted, :boolean

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

    field :can_apply_to_workshops, :boolean do
      resolve fn _args, %{source: source} ->
        {:ok, User.can_apply_to_workshops(source)}
      end
    end

    field :can_apply_to_hackathon, :boolean do
      resolve fn _args, %{source: source} ->
        {:ok, User.can_apply_to_hackathon(source)}
      end
    end

    field :ai_competition_bot, :ai_competition_bot do
      arg :id, :string

      resolve fn %{id: id}, %{source: source} ->
        {:ok, Bots.user_bot(id, source)}
      end
    end

    field :current_team, :team do
      resolve fn _args, %{source: source} ->
        team = Repo.preload(source, :teams).teams
          |> Enum.at(0)
          |> Repo.preload([:invites, :memberships])

        {:ok, team}
      end
    end

    field :current_ai_competition_bot, :ai_competition_bot do
      resolve fn _args, %{source: source} ->
        {:ok, Bots.current_bot(source)}
      end
    end

    field :teams, list_of(:team), resolve: assoc(:teams)
    field :invites, list_of(:invite), resolve: assoc(:invites)
    field :invitations, list_of(:invite), resolve: assoc(:invitations)
    field :ai_competition_bots, list_of(:ai_competition_bot), resolve: assoc(:ai_competition_bots)
    field :workshops, list_of(:workshop), resolve: assoc(:workshops)
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
    field :id, :string
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

    field :attendances, list_of(:attendance), resolve: assoc(:attendances)
    field :users, list_of(:user) do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        role = current_user && current_user.role
        case role do
          "admin" -> {:ok, Repo.preload(source, :users).users}
          _ -> {:ok, []}
        end
      end
    end
  end

  object :attendance do
    field :id, :string
    field :checked_in, :boolean

    field :user, :user, resolve: assoc(:user)
  end

  #============================================================================ Admin
  object :admin_stats do
    field :users, :json
    field :roles, :json
    field :teams, :json
    field :workshops, :json
  end

  connection node_type: :flyby
  object :flyby do
    field :id, :string
    field :name, :string
    field :email, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if current_user && current_user.role == "admin" do
          {:ok, source.email}
        else
          {:ok, nil}
        end
      end
    end
    field :time, :integer
  end
end
