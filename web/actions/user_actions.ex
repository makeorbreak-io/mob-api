defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.{User, UserActions, Invite}

  def all do
    Enum.map(Repo.all(User), fn(user) -> UserActions.add_current_team(user) end)
  end

  def get(id) do
    Repo.get!(User, id)
    |> add_current_team
  end

  def create(user_params) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        from(i in Invite, where: i.email == ^user.email, update: [
          set: [invitee_id: ^user.id]
        ]) |> Repo.update_all([])

        {:ok, add_current_team(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(conn, id, user_params) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Repo.get!(User, id)

    changeset = apply(User, String.to_atom("#{current_user.role}_changeset"),
      [user, user_params])

    case Repo.update(changeset) do
      {:ok, user} -> {:ok, add_current_team(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(id) do
    user = Repo.get!(User, id)
    Repo.delete!(user)
  end

  def add_current_team(user) do
    user = user
    |> Repo.preload([
      :workshops,
      invitations: [:host, :team, :invitee],
      teams: [
        team: [
          :invites,
          :project,
          members: [:user]
        ]
      ]
    ])

    # Change this condition when year are added to teams
    membership = List.first(user.teams)

    Map.put(user, :team, membership)
  end
end
