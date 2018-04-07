defmodule Api.AICompetition do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts
  alias Api.Accounts.User
  alias Api.AICompetition.{Games, Game, GameBot, Bot, Bots, GameTemplates}

  def users_with_valid_bots do
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
  end

  def user_pairs(users) do
    users
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
  end

  def perform_training_matches do
    templates = [
      &GameTemplates.ten_by_ten/2,
      &GameTemplates.five_by_eleven/2,
    ]

    users_with_valid_bots
    |> user_pairs
    |> Enum.flat_map(fn [u1, u2] ->
      templates
      |> Enum.map(fn template ->
        Games.create_game(
          Bots.current_bot(u1),
          Bots.current_bot(u2),
          false,
          nil,
          template
        )
      end)
    end)
  end

  def schedule_run(run_name, timestamp, templates \\ []) do
    users_with_valid_bots()
    |> user_pairs
    |> Enum.flat_map(fn [u1, u2] ->
      templates |> Enum.map(fn template ->
        Games.create_game(
          Bots.current_bot(u1, timestamp),
          Bots.current_bot(u2, timestamp),
          true,
          run_name,
          template
        )
      end)
    end)
  end

  # def leaderboard do
  #   q = from gb in GameBot,
  #     join: g in assoc(gb, :game),
  #     where: g.status == "processed",
  #     where: not is_nil(gb.score),
  #     preload: [bot: :user]

  #   q
  #   |> Repo.all
  #   |> Enum.group_by(fn gb -> gb.ai_competition_game_id end)
  #   |> Map.values
  #   |> Enum.map(fn [a, b] ->
  #     cond do
  #       a.score == b.score -> nil
  #       a.score > b.score -> a.bot.user.id
  #       a.score < b.score -> b.bot.user.id
  #     end
  #   end)
  #   |> Enum.filter(fn x -> x != nil end)
  #   |> Enum.sort
  #   |> Enum.chunk_by(fn x -> x end)
  #   |> Enum.reduce(%{}, fn wins, all ->
  #     all
  #     |> Map.put(Enum.at(wins, 0), Enum.count(wins))
  #   end)
  #   |> Enum.sort(fn {_, wins1}, {_, wins2} -> wins1 > wins2 end)
  #   |> Enum.map(&Tuple.to_list/1)
  #   |> Enum.map(fn [id, score] ->
  #     [Accounts.User.display_name(Accounts.get_user(id)), score ]
  #   end)
  # end

  # def set_all_game_bots_score do
  #   q = from g in Game,
  #     join: gb in assoc(g, :game_bots),
  #     where: is_nil(gb.score),
  #     where: g.status == "processed",
  #     where: not is_nil(g.final_state)

  #   Api.Ecto.stream(Repo, q)
  #   |> Stream.take(2000)
  #   |> Enum.to_list
  #   |> Enum.map(fn game ->
  #     Games.set_result(game.id)
  #   end)

  # end

end
