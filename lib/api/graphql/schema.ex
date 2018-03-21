defmodule Api.GraphQL.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema

  alias Api.GraphQL.Middleware.{RequireAuthn}
  alias Api.GraphQL.Resolvers

  alias Api.Accounts
  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Competitions.Competition
  alias Api.Teams
  alias Api.Teams.{Team, Invite}
  alias Api.AICompetition.{Game, Games, Bots, Bot}
  alias Api.Workshops.Workshop
  alias Api.Integrations.Medium

  import_types Api.GraphQL.Types

  query do
    #
    # single resources
    field :me, :user do
      resolve &Resolvers.me/2
    end

    # field :competition, :competition do
    #   arg :id, non_null(:string)

    #   resolve Resolvers.by_id(Competition)
    # end

    field :team, :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve Resolvers.by_id(Team)
    end

    # field :user, :user do
    #   arg :id, non_null(:string)

    #   resolve Resolvers.by_id(User)
    # end

    # field :workshop, :workshop do
    #   arg :slug, non_null(:string)

    #   resolve Resolvers.by_attr(Workshop, :slug)
    # end

    #
    # non-paginated collections
    field :medium, :medium do
      resolve fn _args, _info ->
        json = Medium.get_latest_posts(2)
        {:ok, %{posts:
          json
          |> Map.get("payload")
          |> Map.get("references")
          |> Map.get("Post")
          |> Map.values
        }}
      end
    end

    #
    # paginated resource collections
    # connection field :teams, node_type: :team do
    #   arg :order_by, :string

    #   middleware RequireAuthn

    #   resolve Resolvers.all(Team)
    # end

    # connection field :users, node_type: :user do
    #   arg :order_by, :string

    #   middleware RequireAuthn

    #   resolve Resolvers.all(User)
    # end

    # connection field :workshops, node_type: :workshop do
    #   arg :order_by, :string

    #   resolve Resolvers.all(Workshop)
    # end

    field :ai_games, list_of(:ai_competition_game) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        {:ok, Games.user_games(current_user)}
      end

      # resolve Resolvers.all(Game)
    end
  end

  mutation do
    @desc "Authenticates a user and returns a JWT"
    field :authenticate, type: :string do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve Resolvers.run_with_args(
        &Accounts.create_session/2,
        [
          [:args, :email],
          [:args, :password],
        ]
      )
    end

    @desc "Registers an user and returns a JWT"
    field :register, type: :string do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve Resolvers.run(&Accounts.create_user/1)
    end

    @desc "Updates the current user"
    field :update_me, type: :user do
      arg :user, non_null(:user_input)

      middleware RequireAuthn

      resolve fn %{user: params}, %{context: %{current_user: current_user}} ->
        # {:ok, user} = Accounts.update_user(current_user, current_user.id, params)
        # user
        Accounts.update_user(current_user, current_user.id, params)
      end
    end

    @desc "Creates a team"
    field :create_team, type: :team do
      arg :team, non_null(:team_input)

      middleware RequireAuthn

      resolve fn %{team: params}, %{context: %{current_user: current_user}} ->
        team_params = params |> Map.merge(%{competition_id: Competitions.default_competition.id})

        Teams.create_team(current_user, team_params)
      end
    end

    @desc "Updates a team"
    field :update_team, type: :team do
      arg :id, non_null(:string)
      arg :team, non_null(:team_input)

      middleware RequireAuthn

      resolve fn %{id: id, team: params}, %{context: %{current_user: current_user}} ->
        Teams.update_team(current_user, id, params)
      end
    end

    @desc "Deletes a team"
    field :delete_team, type: :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.delete_team(current_user, id)
      end
    end

    @desc "Invites new members to a team"
    field :invite, type: :team do
      arg :id, non_null(:string)
      arg :emails, non_null(list_of(:string))

      middleware RequireAuthn

      resolve fn %{id: id, emails: emails}, %{context: %{current_user: current_user}} ->
        Enum.each emails, fn email ->
          Teams.create_invite(current_user.id, id, %{email: email})
        end

        {:ok, Teams.get_team(id)}
      end
    end

    @desc "Accepts an invite"
    field :accept_invite, type: :user do
      arg :id, non_null(:string)

      middleware RequireAuthn
      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.accept_invite(current_user, id)
      end
    end

    @desc "Rejects an invite"
    field :reject_invite, type: :user do
      arg :id, non_null(:string)

      middleware RequireAuthn
      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.reject_invite(current_user, id)
      end
    end

    @desc "Revokes an invite"
    field :revoke_invite, type: :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.delete_invite(current_user, id)
      end
    end

    @desc "Removes a user from team"
    field :remove_from_team, type: :team do
      arg :user_id, non_null(:string)
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id, user_id: user_id}, %{context: %{current_user: current_user}} ->
        Teams.remove_membership(current_user, id, user_id)

        {:ok, Teams.get_team(id)}
      end
    end

    @desc "Creates an AI competition bot"
    field :create_ai_competition_bot, :user do
      arg :bot, non_null(:ai_competition_bot_input)

      middleware RequireAuthn

      resolve fn %{bot: bot}, %{context: %{current_user: current_user}} ->
        Bots.create_bot(current_user, bot)

        {:ok, current_user}
      end
    end
  end

end
