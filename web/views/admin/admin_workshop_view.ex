defmodule Api.Admin.WorkshopView do
  use Api.Web, :view

  def render("index.json", %{workshops: workshops}) do
    %{data: render_many(workshops, __MODULE__, "workshop.json")}
  end

  def render("show.json", %{workshop: workshop}) do
    %{data: render_one(workshop, __MODULE__, "workshop.json")}
  end

  def render("workshop.json", %{workshop: workshop}) do
    %{
      slug: workshop.slug,
      name: workshop.name,
      summary: workshop.summary,
      description: workshop.description,
      speaker: workshop.speaker,
      participant_limit: workshop.participant_limit,
      year: workshop.year,
      speaker_image: workshop.speaker_image,
      banner_image: workshop.banner_image,
      attendees: if Ecto.assoc_loaded?(workshop.attendees) do
        render_many(workshop.attendees, UserView, "user_short.json")
      end
    }
  end
end