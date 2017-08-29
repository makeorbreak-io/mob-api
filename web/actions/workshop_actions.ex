defmodule Api.WorkshopActions do
  use Api.Web, :action

  alias Api.{Workshop, WorkshopAttendance, Repo, Email, Mailer}
  alias Guardian.{Plug}
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

  def join(conn, id) do
    user = Plug.current_resource(conn)
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from w in "users_workshops", where: w.workshop_id == type(^workshop.id, Ecto.UUID)
    attendees_count = Repo.aggregate(query, :count, :workshop_id)

    if attendees_count < workshop.participant_limit do
      changeset = WorkshopAttendance.changeset(%WorkshopAttendance{},
        %{user_id: user.id, workshop_id: workshop.id})

      case Repo.insert(changeset) do
        {:ok, attendance} ->
          Email.joined_workshop_email(user, workshop) |> Mailer.deliver_later
          {:ok, attendance}
        {:error, _} -> {:error, "Unable to create workshop attendance"}
      end
    else
      {:error, "Workshop is already full"}
    end
  end

  def leave(conn, id) do
    user = Plug.current_resource(conn)
    workshop = Repo.get_by!(Workshop, slug: id)

    query = from(w in "users_workshops",
      where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        and w.user_id == type(^user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} ->
        {:ok}
      {0, nil} ->
        {:error, "User isn't an attendee of the workshop"}
    end
  end
end
