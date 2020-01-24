defmodule Api.Repo do
  use Ecto.Repo, otp_app: :api, adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DB_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DB_URL"))}
  end
end
