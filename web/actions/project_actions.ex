defmodule Api.ProjectActions do
  use Api.Web, :action

  alias Api.{Project}

  def all do
    Repo.all(Project)
  end

  def get(id) do
    Repo.get!(Project, id)
  end

  def create(project_params) do
    changeset = Project.changeset(%Project{}, project_params)

    Repo.insert(changeset)
  end

  def update(id, project_params) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, project_params)

    Repo.update(changeset)
  end

  def delete(id) do
    project = Repo.get!(Project, id)
    Repo.delete!(project)
  end
end
