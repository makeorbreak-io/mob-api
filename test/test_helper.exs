ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(ApiWeb.Repo, :manual)

defmodule ApiWeb.TestHelper do
  alias ApiWeb.{User, Team, Repo, TeamMember, Invite, Workshop, Category,
    StringHelper, Vote, PaperVoteActions, UserHelper}

  @valid_user_attrs %{
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }
  # Commenting this instead of deleting because not using this on the create_team
  # function will break the github integration tests once they are uncommented.
  # So I'm keeping it for future reference.
  # @valid_team_attrs %{
  #   name: "awesome team",
  #   repo: %{"name" => "awesome-team"}
  # }
  @valid_workshop_attrs %{
    name: "awesome workshop",
    slug: "awesome-workshop",
    participant_limit: 1,
    short_date: "SUNDAY 10TH — 10:30"
  }

  defp add_email(params) do
    Map.merge(
      %{email: "#{to_string(:rand.uniform())}@email.com"},
      params
    )
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

  def create_team(user, params \\ nil) do
    params = params || %{name: "awesome team #{to_string(:rand.uniform())}"}
    team = %Team{}
    |> Team.changeset(params, Repo)
    |> Repo.insert!

    Repo.insert! %TeamMember{user_id: user.id, team_id: team.id, role: "owner"}

    team
  end

  def create_workshop(params \\ @valid_workshop_attrs) do
    %Workshop{}
    |> Workshop.changeset(params)
    |> Repo.insert!
  end

  def create_invite(params) do
    %Invite{}
    |> Invite.changeset(params)
    |> Repo.insert!
  end

  def create_membership(team, user) do
    %TeamMember{}
    |> TeamMember.changeset(%{
      user_id: user.id,
      team_id: team.id,
    })
    |> Repo.insert!
  end

  def create_category(params \\ %{}) do
    %Category{}
    |> Category.changeset(
      %{
        name: StringHelper.slugify("cool #{:rand.uniform()}"),
      }
      |> Map.merge(params)
    )
    |> Repo.insert!
  end

  def check_in_everyone(people \\ nil) do
    people = people || Repo.all(User)

    people
    |> Enum.map(fn user ->
      user
      |> User.admin_changeset(%{checked_in: true})
      |> Repo.update!
    end)
  end

  def make_teams_eligible(teams \\ nil) do
    teams = teams || Repo.all(Team)

    teams
    |> Enum.map(fn team ->
      team
      |> Team.admin_changeset(%{eligible: true}, Repo)
      |> Repo.update!
    end)
  end

  def create_vote(user, category_name, ballot) do
    category = Repo.get_by(Category, name: category_name)

    Repo.insert! %Vote{
      voter_identity: user.voter_identity,
      category_id: category.id,
      ballot: ballot
    }
  end

  def create_paper_vote(category, admin) do
    {:ok, pv} = PaperVoteActions.create(category, admin)
    pv
  end

  def annul_paper_vote(paper_vote, admin) do
    {:ok, pv} = PaperVoteActions.annul(paper_vote, admin)
    pv
  end

  def redeem_paper_vote(paper_vote, team, member, admin) do
    {:ok, pv} = PaperVoteActions.redeem(paper_vote, team, member, admin)
    pv
  end

  def team_short_view(t) do
    %{"id" => t.id, "name" => t.name}
  end

  def team_view(t) do
    %{
      "applied" => t.applied,
      "disqualified_at" => t.disqualified_at,
      "eligible" => t.eligible,
      "id" => t.id,
      "invites" => nil,
      "members" => nil,
      "name" => t.name,
      "prize_preference" => t.prize_preference,
      "project" => nil
    }
  end

  def admin_user_short_view(u) do
    %{
      "display_name" => UserHelper.display_name(u),
      "first_name" => u.first_name,
      "last_name" => u.last_name,
      "gravatar_hash" => UserHelper.gravatar_hash(u),
      "id" => u.id,
      "tshirt_size" => u.tshirt_size,
      "email" => u.email
    }
  end
end
