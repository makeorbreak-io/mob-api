defmodule Api.Repo.Migrations.AddAttributesToProjects do
  use Ecto.Migration

  def change do
	 alter table(:projects) do
    add :team_name, :string
    add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
	 end
  end
end
