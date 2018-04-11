ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule ApiWeb.TestHelper do
  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Workshops.{Workshop, Attendance}
  alias Api.Teams.{Team, Membership, Invite}
  alias Api.Competitions
  alias Api.Competitions.Competition
  alias Api.Suffrages.{Suffrage, Vote, PaperVote}
  alias Api.Competitions.Attendance, as: CompAttendance

  @valid_user_attrs %{
    name: "john doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }

  @valid_workshop_attrs %{
    name: "awesome workshop",
    participant_limit: 1,
    short_date: "SUNDAY 10TH — 10:30"
  }

  @valid_competition_attrs %{
    name: "awesome competition"
  }

  defp add_email(params) do
    Map.merge(
      %{email: "#{to_string(:rand.uniform())}@email.com"},
      params
    )
  end

  defp add_slug(params) do
    Map.merge(%{slug: "workshop-#{to_string(:rand.uniform())}"}, params)
  end

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(
      params
      |> add_email
    )
    |> Repo.insert!
  end

  def create_admin(params \\ @valid_user_attrs) do
    %User{}
    |> User.admin_changeset(
      params
      |> add_email
      |> Map.merge(%{role: "admin"})
    )
    |> Repo.insert!
  end

  def create_team(user, competition, params \\ nil) do
    params = params || %{name: "awesome team #{to_string(:rand.uniform())}"}
    team = %Team{competition_id: competition.id}
    |> Team.changeset(params)
    |> Repo.insert!

    Repo.insert! %Membership{user_id: user.id, team_id: team.id, role: "owner"}

    team
  end

  def create_competition(params \\ @valid_competition_attrs) do
    %Competition{}
    |> Competition.changeset(params)
    |> Repo.insert!
  end

  def create_competition_attendance(competition, user) do
    %CompAttendance{}
    |> CompAttendance.changeset(%{competition_id: competition.id, attendee: user.id})
    |> Repo.insert!
  end

  def create_workshop(params \\ @valid_workshop_attrs) do
    %Workshop{}
    |> Workshop.changeset(params |> add_slug)
    |> Repo.insert!
  end

  def create_workshop_attendance(workshop, user) do
    Repo.insert! %Attendance{workshop_id: workshop.id, user_id: user.id}
    Workshop.changeset(workshop, %{participants_counter: workshop.participants_counter + 1})
    |> Repo.update()
  end

  def create_id_invite(team, host, user) do
    %Invite{}
    |> Invite.changeset(%{
      invitee_id: user.id,
      team_id: team.id,
      host_id: host.id
    })
    |> Repo.insert!
  end

  def create_email_invite(team, host, email) do
    %Invite{}
    |> Invite.changeset(%{
      email: email,
      team_id: team.id,
      host_id: host.id
    })
    |> Repo.insert!
  end

  def create_membership(team, user) do
    %Membership{}
    |> Membership.changeset(%{
      user_id: user.id,
      team_id: team.id,
    })
    |> Repo.insert!
  end

  def create_suffrage(competition) do
    %Suffrage{}
    |> Suffrage.changeset(
      %{
        name: "awesome",
        slug: "awesome",
        competition_id: competition.id
      }
    )
    |> Repo.insert!
  end

  def check_in_everyone(competition_id, people \\ nil) do
    people = people || Repo.all(User)

    people
    |> Enum.map(fn user ->
      Competitions.toggle_checkin(competition_id, user.id)
    end)
  end

  def create_vote(user, suffrage, ballot) do
    %Vote{}
    |> Vote.changeset(
      %{
        voter_identity: user.voter_identity,
        suffrage_id: suffrage.id,
        ballot: ballot
      }
    )
    |> Repo.insert!
  end

  def create_paper_vote(suffrage, admin) do
    %PaperVote{}
    |> PaperVote.changeset(
      %{
        created_by_id: admin.id,
        suffrage_id: suffrage.id
      }
    )
    |> Repo.insert!
  end

  def annul_paper_vote(paper_vote, admin) do
    pv = Repo.get!(PaperVote, paper_vote.id)

    PaperVote.changeset(pv,
      %{
        annulled_by_id: admin.id,
        annulled_at: DateTime.utc_now,
      }
    )
    |> Repo.update!
  end

  def redeem_paper_vote(paper_vote, team, member, admin) do
    pv = Repo.get!(PaperVote, paper_vote.id)

    PaperVote.changeset(pv,
      %{
        redeemed_admin_id: admin.id,
        redeemed_at: DateTime.utc_now,
        redeeming_member_id: member.id,
        team_id: team.id
      }
    )
    |> Repo.update!
    pv
  end
end
