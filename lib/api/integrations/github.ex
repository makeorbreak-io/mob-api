defmodule Api.Integrations.Github do
  import Ecto.Query, warn: false

  alias Tentacat.{Client, Repositories, Repositories.Collaborators}
  import ApiWeb.StringHelper

  @github_token Application.get_env(:api, :github_token)
  @organization Application.get_env(:api, :github_org)
  @github_regex ~r/^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\-][a-z0-9\-]*)(?:\/\w*)?$/i
  @permissions %{permissions: "push"}

  def init do
    Client.new(%{access_token: @github_token})
  end

  def create_repo(team) do
    client = init()

    case Repositories.org_create(@organization, slugify(team.name),
      client, [private: false]) do
        {201, repo} -> {:ok, repo}
        {_, error} -> {:error, error["message"]}
    end
  end

  def add_collaborator(_, username) when is_nil(username), do: :no_username
  def add_collaborator(repo, username) do
    client = init()

    if is_url?(username) do
      Collaborators.add(@organization, repo["name"],
        username_from_url(username), @permissions, client)
    else
      Collaborators.add(@organization, repo["name"], username, @permissions, client)
    end
  end

  defp username_from_url(url) do
    case Regex.run(@github_regex, url) do
      [_, username] -> username
      nil -> nil
    end
  end

  defp is_url?(url) do
    Regex.match?(@github_regex, url)
  end
end
