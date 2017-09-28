defmodule ApiWeb.WorkshopActions do
  use Api.Web, :action

  alias Api.{Mailer}
  alias ApiWeb.{Workshop, WorkshopAttendance, Email}
  import Ecto.Query

  def all do
    Repo.all(Workshop)
    |> add_participant_count()
  end

  def get(id) do
    Repo.get_by!(Workshop, slug: id)
    |> add_participant_count()
  end

  def create(workshop_params) do
    changeset = Workshop.changeset(%Workshop{}, workshop_params)

    case Repo.insert(changeset) do
      {:ok, workshop} -> {:ok, add_participant_count(workshop)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(id, workshop_params) do
    workshop = Repo.get_by!(Workshop, slug: id)
    changeset = Workshop.changeset(workshop, workshop_params)

    case Repo.update(changeset) do
      {:ok, workshop} -> {:ok, add_participant_count(workshop)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    workshop = Repo.get_by!(Workshop, slug: id)
    Repo.delete!(workshop)
  end

  def join(current_user, id) do
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from w in WorkshopAttendance, where: w.workshop_id == type(^workshop.id, Ecto.UUID)
    attendees_count = Repo.aggregate(query, :count, :workshop_id)

    if attendees_count < workshop.participant_limit do
      changeset = WorkshopAttendance.changeset(%WorkshopAttendance{},
        %{user_id: current_user.id, workshop_id: workshop.id})

      case Repo.insert(changeset) do
        {:ok, attendance} ->
          Email.joined_workshop_email(current_user, workshop) |> Mailer.deliver_later
          {:ok, attendance}
        {:error, _} -> :join_workshop
      end
    else
      :workshop_full
    end
  end

  def leave(current_user, id) do
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from(w in WorkshopAttendance,
      where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        and w.user_id == type(^current_user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} -> {:ok}
      {0, nil} -> :workshop_attendee
    end
  end

  def toggle_checkin(id, user_id, value) do
    workshop = Repo.get_by!(Workshop, slug: id)

    result = from(a in WorkshopAttendance,
      where: a.workshop_id == ^workshop.id,
      where: a.user_id == ^user_id,
      update: [set: [checked_in: ^value]])
      |> Repo.update_all([])

    case result do
      {1, _} ->
        workshop = Repo.get(Workshop, workshop.id)
        |> add_participant_count()

        {:ok, workshop}
      {0, _} -> if value, do: :checkin, else: :remove_checkin
    end
  end

  defp add_participant_count(workshops) when is_list(workshops) do
    Enum.map(workshops, &add_participant_count/1)
  end
  defp add_participant_count(workshop) do
    workshop =
      unless Ecto.assoc_loaded?(workshop.attendances) do
        Repo.preload(workshop, attendances: [:user])
      end

    Map.put(workshop, :participants, Enum.count(workshop.attendances))
  end
end
