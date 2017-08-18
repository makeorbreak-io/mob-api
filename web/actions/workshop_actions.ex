defmodule Api.WorkshopActions do
  use Api.Web, :action

  alias Api.{Workshop, WorkshopAttendance, Repo}
  import Ecto.Query

  def all(permissions) do
    workshops = Repo.all(Workshop)
    case permissions do
      "admin" -> Repo.preload(workshops, :attendees)
      "participant" -> workshops
    end
  end

  def get(id, permissions) do
    workshop = Repo.get_by!(Workshop, slug: id)
    
    case permissions do
      "admin" -> Repo.preload(workshop, :attendees)
      "participant" -> workshop
    end
  end

  def create(workshop_params) do
    changeset = Workshop.changeset(%Workshop{}, workshop_params)

    Repo.insert(changeset)
  end

  def update(id, workshop_params) do
    workshop = Repo.get_by!(Workshop, slug: id)
    changeset = Workshop.changeset(workshop, workshop_params)

    Repo.update(changeset)
  end

  def delete(id) do
    workshop = Repo.get_by!(Workshop, slug: id)
    Repo.delete!(workshop)
  end

  def join(conn, id) do
    case Guardian.Plug.current_resource(conn) do
      nil -> {:error, "Authentication required"}
      user ->
        workshop = Repo.get_by!(Workshop, slug: id)

        query = from w in "users_workshops", where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        attendees_count = Repo.aggregate(query, :count, :workshop_id)

        if attendees_count < workshop.participant_limit do
          changeset = WorkshopAttendance.changeset(%WorkshopAttendance{},
            %{user_id: user.id, workshop_id: workshop.id})

          case Repo.insert(changeset) do
            {:ok, attendance} -> {:ok, attendance}
            {:error, _} -> {:error, "Unable to create workshop attendance"}
          end
        else
          {:error, "Workshop is already full"}
        end
    end
  end

  def leave(conn, id) do
    case Guardian.Plug.current_resource(conn) do
      nil -> {:error, "Authentication required"}
      user ->
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
end