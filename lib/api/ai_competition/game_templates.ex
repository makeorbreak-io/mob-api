defmodule Api.AICompetition.GameTemplates do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.AICompetition.{Games, GameTemplate}

  # def default(game_id) do
  #   bots = Games.get_game(game_id).game_bots

  #   bot1 = Enum.at(bots, 0).bot
  #   bot2 = Enum.at(bots, 1).bot

  #   query = from t in GameTemplate,
  #           where: t.slug == "10x10"

  #   Repo.one(query) || Repo.insert!(%GameTemplate{
  #     initial_state: ten_by_ten(bot1, bot2),
  #     slug: "10x10",
  #   })
  # end

  def ten_by_ten(bot1, bot2) do
    id1 = bot1.id
    id2 = bot2.id

    %{
      width: 10,
      height: 10,
      turns_left: 100,
      colors: [
        [id1,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],
        [nil,nil,nil,nil,nil,nil,nil,nil,nil,id2]
      ],
      player_positions: %{} |> Map.put(id1, [0, 0]) |> Map.put(id2, [9, 9]),
      previous_actions: [],
    }
  end

end
