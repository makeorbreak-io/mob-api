defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.User

  def all do
    Repo.all(User)
    |> Repo.preload(:team)
  end

  def get(id) do
    user = Repo.get!(User, id)
    |> Repo.preload([:team, :memberships])

    team = 
    cond do
      !is_nil(user.team) -> Map.merge(%{role: "owner"}, user.team)
      !Enum.empty?(user.memberships) ->
        Map.merge(%{role: "member"}, List.first(user.memberships))
      true -> nil
    end

    Kernel.put_in(user.team, team)
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
