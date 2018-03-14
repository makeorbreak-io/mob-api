defmodule Api.AICompetition.Bots do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.AICompetition.Bot

  @ai_competition_host Application.get_env(:api, :ai_competition_host)
  @http Application.get_env(:api, :http_lib)

  def get_bot(id) do
    Repo.get!(Bot, id)
  end

  def user_bot(id, user) do
    from(b in Bot,
      where: b.id == ^id and b.user_id == ^user.id
    )
    |> Repo.one
  end

  def create_bot(current_user, params) do
    revision = Repo.aggregate(
      from(s in Bot,
      where: s.user_id == ^current_user.id and s.title == ^params.title),
      :count, :id
    ) + 1

    changeset = Bot.changeset(
      %Bot{},
      Map.merge(params, %{user_id: current_user.id, revision: revision})
    )

    case Repo.insert!(changeset) do
      bot ->
        submit_to_ai_server(bot, "compile")
        {:ok, bot}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def current_bot(user) do
    from(Bot,
      where: [user_id: ^user.id],
      order_by: [desc: :inserted_at],
      order_by: [desc: :revision],
      limit: 1
    )
    |> Repo.one
  end

  defp submit_to_ai_server(bot, "compile") do
    body = %{
      type: "compile",
      payload: %{
        program_id: bot.id,
        sdk: bot.sdk,
        source_code: bot.source_code,
      },
      callback_url: System.get_env("AI_CALLBACK_URL") <> "/api/bots/" <> bot.id,
      auth_token: bot.id,
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> System.get_env("AI_SERVER_TOKEN")},
    ]

    url = System.get_env("AI_SERVER_HOST") <> "/jobs"

    HTTPoison.post(url, Poison.encode!(body), headers)
  end
end
