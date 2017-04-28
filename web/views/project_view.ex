defmodule Api.ProjectView do
  use Api.Web, :view

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, Api.ProjectView, "project.json")}
  end

  def render("show.json", %{project: project}) do
    %{data: render_one(project, Api.ProjectView, "project.json")}
  end

  def render("project.json", %{project: project}) do
    %{
      id: project.id,
      name: project.name,
      description: project.description,
      technologies: project.technologies
    }
  end
end
