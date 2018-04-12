defmodule Api.GraphQL.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}
  alias Api.GraphQL.Resolvers

  alias Api.Repo # FIXME: this should not be here

  alias Api.Accounts
  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Integrations.Medium
  alias Api.Flybys
  alias Api.Teams
  alias Api.Teams.{Team}
  alias Api.Competitions
  alias Api.AICompetition
  alias Api.AICompetition.{Games, Bots, Bot}
  alias Api.Stats
  alias Api.Suffrages
  alias Api.Workshops
  alias Api.Workshops.{Workshop}

  import_types Api.GraphQL.Types

  #---------------------------------------------------------------------------- Queries
  query do

    field :me, :user do
      resolve &Resolvers.me/2
    end

    #-------------------------------------------------------------------------- Publicly available information
    @desc "Single workshop details"
    field :workshop, :workshop do
      arg :slug, non_null(:string)

      resolve Resolvers.by_attr(Workshop, :slug)
    end

    @desc "MoB 2018 FLY paper plane competition entries"
    field :flybys, list_of(:flyby) do
      resolve fn _args, _info -> {:ok, Flybys.all} end
    end

    @desc "workshops list"
    field :workshops, list_of(:workshop) do
      resolve fn _args, _info -> {:ok, Workshops.all} end
    end

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

    #-------------------------------------------------------------------------- Participant / team
    @desc "Single team details"
    field :team, :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve Resolvers.by_id(Team)
    end

    #-------------------------------------------------------------------------- Participant / AI Competition
    @desc "Last 50 AI Competition games for the current user"
    field :ai_games, list_of(:ai_competition_game) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        {:ok, Games.user_games(current_user)}
      end
    end

    #-------------------------------------------------------------------------- Participant / Voting
    @desc "Voting categories"
    field :suffrages, list_of(:suffrage) do
      middleware RequireAuthn

      resolve fn _args, _info ->
        {:ok, Suffrages.all_suffrages}
      end
    end

    field :votes, list_of(:vote) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        Suffrages.get_votes(current_user)
      end
    end

    #-------------------------------------------------------------------------- Admin / dashboard stats
    field :admin_stats, :admin_stats do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {:ok, Stats.get()}
      end
    end

    #-------------------------------------------------------------------------- Admin / Paginated resources
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

    #-------------------------------------------------------------------------- Admin / Non-Paginated resources
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

    field :unredeemed_paper_votes, list_of(:paper_vote) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        suffrage_ids = Competitions.default_competition.suffrages |> Enum.map &(&1.id)

        {
          :ok,
          suffrage_ids
          |> Enum.flat_map(fn id ->
            Suffrages.unredeemed_paper_votes(id)
            |> Repo.all
          end)
        }
      end
    end

    field :redeemed_paper_votes, list_of(:paper_vote) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        suffrage_ids = Competitions.default_competition.suffrages |> Enum.map &(&1.id)

        {
          :ok,
          suffrage_ids
          |> Enum.flat_map(fn id ->
            Suffrages.redeemed_paper_votes(id)
            |> Repo.all
          end)
        }
      end
    end
  end

  #============================================================================ Mutations

  mutation do
    #-------------------------------------------------------------------------- User session
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

    #-------------------------------------------------------------------------- Participant / team & invites
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

    #-------------------------------------------------------------------------- Participant / ai competition
    @desc "Creates an AI competition bot"
    field :create_ai_competition_bot, :user do
      arg :bot, non_null(:ai_competition_bot_input)

      middleware RequireAuthn

      resolve fn %{bot: bot}, %{context: %{current_user: current_user}} ->
        Bots.create_bot(current_user, bot)

        {:ok, current_user}
      end
    end

    #-------------------------------------------------------------------------- Participant / workshops
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

    #-------------------------------------------------------------------------- Participant / voting
    @desc "Casts votes"
    field :cast_votes, :user do
      arg :votes, non_null(:string) # stringified json

      middleware RequireAuthn

      resolve fn %{votes: votes}, %{context: %{current_user: current_user}} ->
        ballots = votes |> Poison.decode! |> Map.to_list
        Suffrages.upsert_votes(current_user, ballots)

        {:ok, Accounts.get_user(current_user.id)}
      end
    end

    #========================================================================== ADMIN

    #-------------------------------------------------------------------------- Admin / workshops
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

    #-------------------------------------------------------------------------- Admin / fly
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

    #-------------------------------------------------------------------------- Admin / users
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

    #-------------------------------------------------------------------------- Admin / teams
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

    @desc "Removes any team membership (admin only)"
    field :remove_any_membership, :team do
      arg :team_id, non_null(:string)
      arg :user_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{team_id: team_id, user_id: user_id}, _info ->
        Teams.remove_any_membership(team_id, user_id)
      end
    end

    @desc "Makes a team eligible for voting"
    field :make_team_eligible, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{eligible: true})
      end
    end

    @desc "Creates a repo on github for a team"
    field :create_team_repo, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        {:ok, nil}
      end
    end

    #-------------------------------------------------------------------------- Admin / AI Competition
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

    #-------------------------------------------------------------------------- Admin / check in
    @desc "Toggles competition check in status for user"
    field :toggle_user_checkin, :user do
      arg :user_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{user_id: user_id}, _info ->
        Competitions.toggle_checkin(Competitions.default_competition.id, user_id)
      end
    end

    @desc "Toggle workshop check in status for user"
    field :toggle_workshop_checkin, :workshop do
      arg :slug, non_null(:string)
      arg :user_id, non_null(:string)
      arg :value, non_null(:boolean)

      middleware RequireAdmin

      resolve fn %{slug: slug, user_id: user_id, value: value}, _info ->
        Workshops.toggle_checkin(slug, user_id, value)
      end
    end

    #-------------------------------------------------------------------------- Admin / voting
    @desc "Create suffrage (admin only)"
    field :create_suffrage, :suffrage do
      arg :suffrage, non_null(:suffrage_input)

      middleware RequireAdmin

      resolve fn %{suffrage: suffrage}, _info ->
        Suffrages.create_suffrage(suffrage)
      end
    end

    @desc "Delete suffrage (admin only)"
    field :delete_suffrage, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.delete_suffrage(id)
      end
    end

    @desc "Opens voting for a suffrage"
    field :start_suffrage_voting, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.start_suffrage(id)
      end
    end

    @desc "Closes voting for a suffrage"
    field :end_suffrage_voting, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.end_suffrage(id)
      end
    end

    @desc "Disqualify team (admin only)"
    field :disqualify_team, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Competitions.default_competition.suffrages
        |> Enum.each(fn suffrage ->
          Suffrages.disqualify_team(id, suffrage.id, current_user)
        end)

        {:ok, Teams.get_team(id)}
      end
    end

    @desc "Creates a paper vote"
    field :create_paper_vote, :paper_vote do
      arg :suffrage_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{suffrage_id: suffrage_id}, %{context: %{current_user: current_user}} ->
        pv = Suffrages.create_paper_vote(suffrage_id, current_user)
      end
    end

    @desc "Redeems a paper vote"
    field :redeem_paper_vote, :paper_vote do
      arg :paper_vote_id, non_null(:string)
      arg :user_id, non_null(:string)
      arg :team_id, non_null(:string)

      middleware RequireAdmin

      resolve fn args, info ->
        %{paper_vote_id: paper_vote_id, user_id: user_id, team_id: team_id} = args
        %{context: %{current_user: current_user}} = info

        paper_vote = Suffrages.get_paper_vote(paper_vote_id)
        user = Accounts.get_user(user_id)
        team = Teams.get_team(team_id)

        Suffrages.redeem_paper_vote(paper_vote, team, user, paper_vote.suffrage, current_user)
      end
    end

    @desc "Annuls a paper vote"
    field :annul_paper_vote, :paper_vote do
      arg :paper_vote_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{paper_vote_id: paper_vote_id}, %{context: %{current_user: current_user}} ->
        paper_vote = Suffrages.get_paper_vote(paper_vote_id)

        Suffrages.annul_paper_vote(paper_vote, current_user, paper_vote.suffrage)
      end
    end

  end
end
