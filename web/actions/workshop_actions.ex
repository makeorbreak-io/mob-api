defmodule Api.WorkshopActions do
  use Api.Web, :action

  alias Api.{Workshop, WorkshopAttendance, Repo, Email, Mailer}
  import Ecto.Query

  def all do
    Repo.all(Workshop)
    |> Repo.preload(:attendees)
    |> Enum.map(fn(workshop) ->
      Map.put(workshop, :participants, Enum.count(workshop.attendees))
    end)
  end

  def get(id) do
    workshop = Repo.get_by!(Workshop, slug: id)
    |> Repo.preload(:attendees)

    Map.put(workshop, :participants, Enum.count(workshop.attendees))
  end

  def create(workshop_params) do
    changeset = Workshop.changeset(%Workshop{}, workshop_params)

    case Repo.insert(changeset) do
      {:ok, workshop} -> {:ok, Map.put(workshop, :participants, 0)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(id, workshop_params) do
    workshop = Repo.get_by!(Workshop, slug: id)
    changeset = Workshop.changeset(workshop, workshop_params)

    case Repo.update(changeset) do
      {:ok, workshop} ->
        workshop = workshop |> Repo.preload(:attendees)
        {:ok, Map.put(workshop, :participants, Enum.count(workshop.attendees))}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    workshop = Repo.get_by!(Workshop, slug: id)
    Repo.delete!(workshop)
  end

  def join(current_user, id) do
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from w in "users_workshops", where: w.workshop_id == type(^workshop.id, Ecto.UUID)
    attendees_count = Repo.aggregate(query, :count, :workshop_id)

    if attendees_count < workshop.participant_limit do
      changeset = WorkshopAttendance.changeset(%WorkshopAttendance{},
        %{user_id: current_user.id, workshop_id: workshop.id})

      case Repo.insert(changeset) do
        {:ok, attendance} ->
          Email.joined_workshop_email(current_user, workshop) |> Mailer.deliver_later
          {:ok, attendance}
        {:error, _} -> {:error, :join_workshop}
      end
    else
      {:error, :workshop_full}
    end
  end

  def leave(current_user, id) do
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from(w in "users_workshops",
      where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        and w.user_id == type(^current_user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} -> {:ok}
      {0, nil} -> {:error, :workshop_attendee}
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
      {1, _} -> :ok
      {0, _} -> if value, do: {:error, :checkin}, else: {:error, :remove_checkin}
    end
  end
end
