defmodule ApiWeb.BotsController do
  use Api.Web, :controller

  alias Api.Repo
  alias Api.AICompetition
  alias Api.AICompetition.{Bot, Bots, Games}

  def callback(conn, %{"id" => id, "status" => status, "result" => result}) do
    bot = Bots.get_bot(id)

    changeset = Bot.changeset(bot, %{
      status: status,
      compilation_output: result,
    })

    Repo.update(changeset)

    if status == "processed" do
      AICompetition.perform_training_matches
    end

    send_resp(conn, 200, "")
  end

end
