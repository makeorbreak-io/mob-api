defmodule Api.Workshops do
  import Ecto.Query, warn: false

  alias Api.{Mailer, Repo}
  alias Api.{Workshops.Workshop, Workshops.Attendance}
  alias Api.Notifications.Emails

  def all do
    Repo.all(Workshop)
  end

  def get(slug) do
    Repo.get_by(Workshop, slug: slug)
  end

  def create(workshop_params) do
    changeset = Workshop.changeset(%Workshop{}, workshop_params)

    Repo.insert(changeset)
  end

  def update(slug, workshop_params) do
    workshop = get(slug)
    changeset = Workshop.changeset(workshop, workshop_params)

    Repo.update(changeset)
  end

  def delete(slug) do
    workshop = get(slug)
    Repo.delete(workshop)
  end

  def join(user, slug) do
    workshop = get(slug)

    query = from w in Attendance, where: w.workshop_id == type(^workshop.id, Ecto.UUID)
    attendees_count = Repo.aggregate(query, :count, :workshop_id)

    if attendees_count < workshop.participant_limit do
      changeset = Attendance.changeset(%Attendance{},
        %{user_id: user.id, workshop_id: workshop.id})

      case Repo.insert(changeset) do
        {:ok, attendance} ->
          Emails.joined_workshop_email(user, workshop) |> Mailer.deliver_later
          {:ok, attendance}
        {:error, _} -> :join_workshop
      end
    else
      :workshop_full
    end
  end

  def leave(user, slug) do
    workshop = get(slug)

    query = from(w in Attendance,
      where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        and w.user_id == type(^user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} -> :ok
      {0, nil} -> :not_workshop_attendee
    end
  end

  def toggle_checkin(slug, user_id, value) do
    workshop = get(slug)

    result = from(a in Attendance,
      where: a.workshop_id == ^workshop.id,
      where: a.user_id == ^user_id,
      update: [set: [checked_in: ^value]])
      |> Repo.update_all([])

    case result do
      {1, _} -> {:ok, Repo.get(Workshop, workshop.id)}
      {0, _} -> if value, do: :checkin, else: :remove_checkin
    end
  end

  # TODO: Change this to a DB field
  # defp add_participant_count(workshops) when is_list(workshops) do
  #   Enum.map(workshops, &add_participant_count/1)
  # end

  # defp add_participant_count(workshop) do
  #   workshop =
  #     unless Ecto.assoc_loaded?(workshop.attendances) do
  #       Repo.preload(workshop, attendances: [:user])
  #     end

  #   Map.put(workshop, :participants, Enum.count(workshop.attendances))
  # end
end
