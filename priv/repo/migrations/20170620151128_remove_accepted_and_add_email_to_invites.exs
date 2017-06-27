defmodule Api.Repo.Migrations.RemoveAcceptedAndAddEmailToInvites do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      add :email, :string
      remove :accepted
    end

    # drop unique_index(:invites, [:team_id, :invitee_id])
  end
end
