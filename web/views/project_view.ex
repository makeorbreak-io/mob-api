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
      technologies: project.technologies,
      team_name: project.team_name,
      repo: project.repo,
      server: project.server,
      student_team: project.student_team,
      applied_at: project.applied_at,
      completed_at: project.completed_at
    }
  end
end
