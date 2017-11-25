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

  def delete_attendance(id), do: Repo.get(Attendance, id) |> Repo.delete
  def delete_attendance(id, attendee) do
    get_attendance(id, attendee) |> Repo.delete
  end

  def create_attendance(competition_id, attendee_id) do
    %Attendance{}
    |> Attendance.changeset(%{
      competition_id: competition_id,
      attendee: attendee_id
    }) |> Repo.insert()
  end

  def toggle_checkin(competition_id, attendee_id, value) do
    attendance = get_attendance(competition_id, attendee_id)
    attendee = Repo.get(User, attendee_id)

    changeset = Attendance.changeset(attendance, %{checked_in: value})

    case Repo.update(changeset) do
      {:ok, attendance} ->
        value && (Emails.checkin_email(attendee) |> Mailer.deliver_later)
        {:ok, attendance}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # def voting_status(id) do
  #   c = get_competition(id)
  #   now = DateTime.utc_now

  #   cond do
  #     c.voting_ended_at && DateTime.compare(c.voting_ended_at, now) == :lt -> :ended
  #     c.voting_started_at && DateTime.compare(c.voting_started_at, now) == :lt -> :started
  #     true -> :not_started
  #   end
  # end

  # def voting_started_at(id) do
  #   get_competition(id).voting_started_at
  # end

  # def voting_ended_at(id) do
  #   get_competition(id).voting_ended_at
  # end

  # def status do
  #   %{
  #     voting_status: voting_status(),
  #     unredeemed_paper_votes: Voting.unredeemed_paper_votes(),
  #     missing_voters: Voting.missing_voters(),
  #   }
  # end

  # def start_voting(id) do
  #   case voting_status(id) do
  #     :not_started ->
  #       Teams.shuffle_tie_breakers
  #       Teams.assign_missing_preferences
  #       upsert_competition(id, %{voting_started_at: DateTime.utc_now})
  #     :started -> :already_started
  #     :ended -> :already_ended
  #   end
  # end

  # def end_voting(id) do
  #   case voting_status(id) do
  #     :not_started -> :not_started
  #     :started ->
  #       at = DateTime.utc_now
  #       Voting.resolve_voting!(at)
  #       update(id, %{voting_ended_at: at})
  #     :ended -> :already_ended
  #   end
  # end
end
