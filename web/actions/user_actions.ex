defmodule Api.UserActions do
  use Api.Web, :action

  alias Api.{User, UserActions, Invite, Email, Mailer, CompetitionActions}

  def all do
    Enum.map(Repo.all(User), fn(user) -> UserActions.preload_user_data(user) end)
  end

  def get(id) do
    Repo.get!(User, id)
    |> preload_user_data
  end

  def create(user_params) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        from(i in Invite, where: i.email == ^user.email, update: [
          set: [invitee_id: ^user.id]
        ]) |> Repo.update_all([])

        Email.registration_email(user) |> Mailer.deliver_later

        {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :token)

        {:ok, jwt, preload_user_data(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(current_user, id, user_params) do
    user = Repo.get!(User, id)

    changeset = apply(User, String.to_atom("#{current_user.role}_changeset"),
      [user, user_params])

    case Repo.update(changeset) do
      {:ok, user} -> {:ok, preload_user_data(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete(current_user, id) do
    user = Repo.get!(User, id)

    if user.id == current_user.id do
      Repo.delete(user)
    else
      :unauthorized
    end
  end

  def delete_any(id) do
    user = Repo.get!(User, id)
    Repo.delete!(user)
  end

  def toggle_checkin(id, value) do
    case CompetitionActions.voting_status do
      :started ->
        {:error, :already_started}
      _ ->
        user = Repo.get!(User, id)

        changeset = User.admin_changeset(user, %{checked_in: value})

        case Repo.update(changeset) do
          {:ok, user} ->
            value && (Email.checkin_email(user) |> Mailer.deliver_later)
            {:ok, preload_user_data(user)}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def preload_user_data(user) do
    user = user |> Repo.preload([
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
