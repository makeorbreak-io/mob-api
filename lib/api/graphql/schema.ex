defmodule Api.GraphQL.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}
  alias Api.GraphQL.Resolvers

  alias Api.Accounts
  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Integrations.Medium
  alias Api.Flyby
  alias Api.Flybys
  alias Api.Teams
  alias Api.Teams.{Team}
  alias Api.Competitions
  alias Api.AICompetition
  alias Api.AICompetition.{Games, Bots, Bot}
  alias Api.Stats
  alias Api.Workshops
  alias Api.Workshops.{Workshop}

  import_types Api.GraphQL.Types

  query do

    #
    # single resources
    field :me, :user do
      resolve &Resolvers.me/2
    end

    @desc "Single team details"
    field :team, :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve Resolvers.by_id(Team)
    end

    @desc "Single workshop details"
    field :workshop, :workshop do
      arg :slug, non_null(:string)

      resolve Resolvers.by_attr(Workshop, :slug)
    end

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

    # field :ai_leaderboard, :array do
    #   resolve fn _args, _info ->
    #     {:ok, AICompetition.leaderboard}
    #   end
    # end

    field :ai_games, list_of(:ai_competition_game) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        {:ok, Games.user_games(current_user)}
      end
    end

    field :flybys, list_of(:flyby) do
      resolve fn _args, _info -> {:ok, Flybys.all} end
    end

    field :workshops, list_of(:workshop) do
      resolve fn _args, _info -> {:ok, Workshops.all} end
    end

    #
    # admin fields

    #
    # stats / analytics
    field :admin_stats, :admin_stats do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {:ok, Stats.get()}
      end
    end

    #
    # paginated resource collections
    connection field :users, node_type: :user do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(User)
    end

    connection field :teams, node_type: :team do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(Team)
    end

    field :bot, :ai_competition_bot do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve Resolvers.by_id(Bot)
    end

    field :bots, list_of(:ai_competition_bot) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        bots =
        AICompetition.users_with_valid_bots
        |> Enum.map(&(Bots.current_bot(&1)))

        {:ok, bots}
      end
    end

    field :run_bots, list_of(:ai_competition_bot) do
      arg :run_name, non_null(:string)

      middleware RequireAdmin

      resolve fn %{run_name: run_name}, _info ->
        bots =
        AICompetition.users_with_valid_bots
        |> Enum.map(&(Bots.current_bot(&1, AICompetition.ranked_match_config(run_name).timestamp)))

        {:ok, bots}
      end
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

    @desc "Joins a workshop"
    field :join_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Workshops.join(current_user, slug)
      end
    end

    @desc "Leaves a workshop"
    field :leave_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Workshops.leave(current_user, slug)
      end
    end

    #========================================================================== ADMIN

    @desc "Creates a workshop (admin only)"
    field :create_workshop, :workshop do
      arg :workshop, non_null(:workshop_input)

      middleware RequireAdmin

      resolve fn %{workshop: workshop}, _info ->
        Workshops.create(workshop)
      end
    end

    @desc "Updates a workshop (admin only)"
    field :update_workshop, :workshop do
      arg :slug, non_null(:string)
      arg :workshop, non_null(:workshop_input)

      middleware RequireAdmin

      resolve fn %{workshop: workshop, slug: slug}, _info ->
        Workshops.update(slug, workshop)
      end
    end

    @desc "Deletes a workshop (admin only)"
    field :delete_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAdmin

      resolve fn %{slug: slug}, _info ->
        Workshops.delete(slug)
      end
    end

    @desc "Creates a paper plane competition entry"
    field :create_flyby, :flyby do
      arg :flyby, non_null(:flyby_input)

      middleware RequireAdmin

      resolve fn %{flyby: flyby}, _info ->
        Flybys.create(flyby)
      end
    end

    @desc "Deletes a paper plane competition entry"
    field :delete_flyby, :flyby do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Flybys.delete(id)
      end
    end

    # @desc "Send emails to users that haven't applied to the hackathon yet"
    # field :send_not_applied_emails, :string do
    #   middleware RequireAdmin

    #   resolve fn _args, _info ->
    #     Competitions.send_not_applied_email
    #     {:ok, ""}
    #   end
    # end

    # @desc "Send food allergies inquiry emails"
    # field :send_food_allergies_emails, :string do
    #   middleware RequireAdmin

    #   resolve fn _args, _info ->
    #     Competitions.send_food_allergies_email
    #     {:ok, ""}
    #   end
    # end

    @desc "Makes a user admin (admin only)"
    field :make_admin, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.update_any_user(id, %{role: "admin"})
      end
    end

    @desc "Makes a user participant (admin only)"
    field :make_participant, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.update_any_user(id, %{role: "participant"})
      end
    end

    @desc "Removes a user (admin only)"
    field :remove_user, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.delete_any_user(id)
        id
      end
    end

    @desc "Apply the team to the hackathon (admin only)"
    field :apply_team_to_hackathon, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{applied: true})
      end
    end

    @desc "De-apply the team from the hackathon (admin only)"
    field :deapply_team_from_hackathon, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{applied: false})
      end
    end

    @desc "Accepts a team in the hackathon"
    field :accept_team, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.accept_team(id)
      end
    end

    @desc "Delete the team (admin only)"
    field :delete_any_team, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.delete_any_team(id)
        {:ok, id}
      end
    end

    @desc "Runs AI Competition ranked games"
    field :perform_ranked_ai_games, :string do
      arg :name, non_null(:string)

      middleware RequireAdmin

      resolve fn %{name: name}, _info ->
        %{timestamp: timestamp, templates: templates} = AICompetition.ranked_match_config(name)

        AICompetition.perform_ranked_matches(name, timestamp, templates)

        {:ok, ""}
      end
    end

    # @desc "Disqualify team (admin only)"
    # field :disqualify_team, :string do
    #   arg :id, non_null(:string)

    #   middleware RequireAdmin

    #   resolve fn %{id: id}, _info ->
    #     Suffrages.disqualify_team
    #   end
    # end
  end
end
