defmodule ApiWeb.GamesController do
  use Api.Web, :controller

  alias Api.Repo
  alias Api.AICompetition.{Game, Games}

  def callback(conn, %{"id" => id, "status" => status, "result" => result}) do
    game = Games.get_game(id)

    final_state = if status == "processed" do
      {:ok, json} = Poison.decode(result)
      json
    else
      nil
    end

    changeset = Game.changeset(game, %{
      status: status,
      final_state: final_state,
    })

    Repo.update!(changeset)

    send_resp(conn, 200, "")
  end

end

