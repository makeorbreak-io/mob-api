defmodule Api.WorkshopActions do
  use Api.Web, :action

  alias Api.{Workshop}

  def all do
    Repo.all(Workshop)
  end

  def get(id) do
    Repo.get_by!(Workshop, slug: id)
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
end