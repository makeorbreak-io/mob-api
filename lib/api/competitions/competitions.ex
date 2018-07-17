defmodule Api.Competitions do
  import Ecto.Query, warn: false

  alias Api.{Repo, Mailer}
  alias Api.Accounts.User
  alias Api.Competitions.{Competition, Attendance}
  alias Api.Notifications.Emails

  def list_competitions do
    Repo.all(Competition)
  end

  def get_competition(id) do
    Repo.get(Competition, id)
  end

  def default_competition do
    q = from c in Competition,
        where: c.name == "default"

    (Repo.one(q) || Repo.insert!(%Competition{name: "default"}))
    |> Repo.preload(:suffrages)
  end

  def create_competition(competition_params) do
    changeset = Competition.changeset(%Competition{}, competition_params)
    Repo.insert(changeset)
  end

  def update_competition(id, competition_params) do
    changeset = Competition.changeset(get_competition(id), competition_params)
    Repo.update(changeset)
  end

  def delete_competition(id) do
    c = Repo.get(Competition, id)
    Repo.delete!(c)
  end

  def get_attendance(id), do: Repo.get(Attendance, id)
  def get_attendance(competition_id, attendee) do
    Repo.get_by(Attendance, competition_id: competition_id, attendee: attendee)
  end

  def create_attendance(competition_id, attendee_id) do
    changeset = Attendance.changeset(%Attendance{}, %{
      competition_id: competition_id,
      attendee: attendee_id
    })

    Repo.insert(changeset)
  end

  def toggle_checkin(competition_id, attendee_id) do
    attendance = get_attendance(competition_id, attendee_id)
    toggle_checkin(competition_id, attendee_id, !attendance.checked_in)
  end

  def toggle_checkin(competition_id, attendee_id, value) do
    attendance = get_attendance(competition_id, attendee_id)
    attendee = Repo.get(User, attendee_id)

    changeset = Attendance.changeset(attendance, %{checked_in: value})

    case Repo.update(changeset) do
      {:ok, _attendance} ->
        value && (Emails.checkin_email(attendee) |> Mailer.deliver_later)
        {:ok, attendee}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_attendance(id), do: Repo.get(Attendance, id) |> Repo.delete
  def delete_attendance(id, attendee) do
    get_attendance(id, attendee) |> Repo.delete
  end

  # def send_not_applied_email do
  #   non_applied_users =
  #   from(u in User,
  #     join: m in assoc(u, :memberships),
  #     join: t in assoc(m, :team),
  #     where: t.applied == false,
  #     preload: [memberships: {m, team: t}],
  #     select: u
  #   )
  #   |> Repo.all

  #   users_without_team = Enum.filter(
  #     Repo.all(User) |> Repo.preload(:memberships),
  #     fn(user) ->
  #       user.memberships == []
  #     end
  #   )

  #   Enum.each(
  #     non_applied_users ++ users_without_team,
  #     fn(user) ->
  #       Emails.not_applied(user) |> Mailer.deliver_later
  #     end
  #   )
  # end

  # def send_food_allergies_email do
  #   query =
  #   "select users.id,users.name,users.email from users left join users_teams on users.id = users_teams.user_id
  #     left join teams on users_teams.team_id = teams.id
  #     where users_teams.user_id is not null and teams.accepted = true
  #   union distinct
  #   select users.id,users.name,users.email from users left join users_workshops on users.id = users_workshops.user_id
  #     left join workshops on users_workshops.workshop_id = workshops.id
  #     where workshops.year = 2018
  #   union distinct
  #   select users.id,users.name,users.email from users left join ai_competition_bots on users.id = ai_competition_bots.user_id
  #     where ai_competition_bots.user_id is not null;"

  #   result = SQL.query!(Repo, query, [])
  #   cols = Enum.map result.columns, &(String.to_atom(&1))

  #   users = Enum.map result.rows, fn(row) ->
  #     struct(User, Enum.zip(cols, row))
  #   end

  #   Enum.each(users, fn(user) ->
  #     Emails.food_allergies(user)
  #     |> Mailer.deliver_later
  #   end)
  # end
end
