defmodule Api.AICompetition.Games do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.AICompetition.{Game, GameTemplates, GameBot, Bot, Bots}

  def get_game(id) do
    # q = from g in Game,
    #   preload: [:game_bots, :game_template]

    Repo.get!(Game, id)
    |> Repo.preload(:game_bots)
    |> Repo.preload(:game_template)
    # Repo.get!(Game, id)
    # |> Repo.preload(:ai_competition_game_bots)
  end

  def perform_matches do
    # users with valid code bots
    users = from(
      u in User,
      join: s in Bot,
      where:
        s.user_id == u.id and
        not is_nil(s.id) and
        s.status == "processed",
      order_by: u.id,
      distinct: u.id
    )
    |> Repo.all

    users |> Enum.count |> IO.inspect

    # make pairs of users with valid bots face off against each other
    user_pairs = users
    |> Enum.map(fn u1 ->
      users
      |> Enum.map(fn u2 ->
          [u1, u2]
          |> Enum.sort(&(&1.id < &2.id))
        end)
      |> Enum.filter(&(&1 != nil && Enum.at(&1, 0).id != Enum.at(&1, 1).id))
    end)
    |> Enum.flat_map(&(&1))
    |> Enum.uniq

    user_pairs
    |> Enum.map(fn [u1, u2] -> create_game(u1, u2) end)
  end

  def create_game(user1, user2) do
    bot1 = Bots.current_bot(user1)
    bot2 = Bots.current_bot(user2)

    changeset = Game.changeset(%Game{}, %{
      status: "pending",
      initial_state: GameTemplates.ten_by_ten(bot1, bot2),
    })

    case Repo.insert!(changeset) do
      game ->
        Repo.insert!(%GameBot{game: game, bot: bot1})
        Repo.insert!(%GameBot{game: game, bot: bot2})

        submit_to_ai_server(game, "compete")

        {:ok, game}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp submit_to_ai_server(game, "compete") do
    body = %{
      type: "compete",
      payload: %{
        game_state: game.initial_state,
      },
      callback_url: "http://localhost:4000/api/games/" <> game.id,
      auth_token: game.id,
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer derkaderka"},
    ]

    url = "http://localhost:4567/jobs"

    HTTPoison.post(url, Poison.encode!(body), headers)
  end
end
