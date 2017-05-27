defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.User

  def all do
    Repo.all(User)
    |> Repo.preload(:team)
  end

  def get(id) do
    Repo.get!(User, id)
    |> Repo.preload(:team)
  end

  def create(user_params) do
    changeset = User.registration_changeset(%User{}, user_params)

    Repo.insert(changeset)
  end

  def update(id, user_params) do
    user = Repo.get!(User, id)
    |> Repo.preload(:team)

    changeset = User.changeset(user, user_params)

    Repo.update(changeset)
  end

  def delete(id) do
    user = Repo.get!(User, id)
    Repo.delete!(user)
  end
end
