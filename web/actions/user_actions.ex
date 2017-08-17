defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.{User, Invite}

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

    case Repo.insert(changeset) do
      {:ok, user} ->
        from(i in Invite, where: i.email == ^user.email, update: [
          set: [invitee_id: ^user.id]
        ]) |> Repo.update_all([])

        {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(id, user_params, permissions) do
    user = Repo.get!(User, id)
    |> Repo.preload([ :team, :memberships ])

    team = 
      cond do
        !is_nil(user.team) -> Map.merge(%{role: "owner"}, user.team)
        !Enum.empty?(user.memberships) ->
          Map.merge(%{role: "member"}, List.first(user.memberships))
        true -> nil
      end

    changeset =
      case permissions do
        "admin" -> User.admin_changeset(user, user_params)
        "participant" -> User.changeset(user, user_params)
      end

    case Repo.update(changeset) do
      {:ok, user} ->
        user = Kernel.put_in(user.team, team)
        {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
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
