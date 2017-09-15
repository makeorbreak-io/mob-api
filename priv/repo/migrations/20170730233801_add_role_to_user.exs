defmodule Api.Repo.Migrations.AddRoleToUser do
  use Ecto.Migration
  import Ecto.Query

  def change do
    # creating the database type
    execute("create type role as enum ('admin', 'participant')")

    alter table(:users) do
      add :role, :role, null: false, default: "participant"
    end

    flush()

    from(u in "users", update: [set: [role: "participant"]]) |> ApiWeb.Repo.update_all([])
  end
end
