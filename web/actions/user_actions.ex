defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.{User, Invite}

  def all do
    Repo.all(User)
    |> Repo.preload(:team)
  end

  def get(id) do
    Repo.get!(User, id)
    |> Repo.preload([:team, :memberships])
    |> add_team_role
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

  def update(conn, id, user_params) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Repo.get!(User, id)

    user
    |> Repo.preload([:team, :memberships])

    changeset = apply(User, String.to_atom("#{current_user.role}_changeset"),
      [user, user_params])

    case Repo.update(changeset) do
      {:ok, user} -> {:ok, add_team_role(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    user = Repo.get!(User, id)
    Repo.delete!(user)
  end

  defp add_team_role(user) do
    team = 
      cond do
        !is_nil(user.team) -> Map.merge(%{role: "owner"}, user.team)
        !Enum.empty?(user.memberships) ->
          Map.merge(%{role: "member"}, List.first(user.memberships))
        true -> nil
      end

    Kernel.put_in(user.team, team)
  end
end
