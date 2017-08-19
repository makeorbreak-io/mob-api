defmodule Api.ProjectView do
  use Api.Web, :view

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, __MODULE__, "project.json")}
  end

  def render("show.json", %{project: project}) do
    %{data: render_one(project, __MODULE__, "project.json")}
  end

  def render("project.json", %{project: project}) do
    %{
      id: project.id,
      name: project.name,
      description: project.description,
      technologies: project.technologies,
      repo: project.repo,
      server: project.server,
      completed_at: project.completed_at
    }
  end
end
