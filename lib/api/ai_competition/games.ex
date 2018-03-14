defmodule Api.AICompetition.Games do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.AICompetition.{Game, GameTemplates, GameBot, Bot, Bots}

  def get_game(id) do
    Repo.get!(Game, id)
    |> Repo.preload(:game_bots)
    |> Repo.preload(:game_template)
  end

  def user_games(user) do
    games = from(
      g in Game,
      join: gb in GameBot, where: gb.ai_competition_game_id == g.id,
      join: b in Bot, where: b.id == gb.ai_competition_bot_id and b.user_id == ^user.id,
      where: g.status == "processed",
      order_by: [desc: g.updated_at]
    )

    Repo.all(games)
  end

  def perform_matches do
    # users with valid code bots
    users = from(
      u in User,
      join: b in Bot,
      where:
        b.user_id == u.id and
        not is_nil(b.id) and
        b.status == "processed",
      order_by: u.id,
      distinct: u.id
    )
    |> Repo.all

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
      callback_url: System.get_env("AI_CALLBACK_URL") <> "/api/games/" <> game.id,
      auth_token: game.id,
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> System.get_env("AI_SERVER_TOKEN")},
    ]

    url = System.get_env("AI_SERVER_HOST") <> "/jobs"

    HTTPoison.post(url, Poison.encode!(body), headers)
  end
end
