defmodule Api.Repo.Migrations.CreateWorkshops do
  use Ecto.Migration

  def change do
    create table(:workshops, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :name, :string
      add :summary, :string
      add :description, :string
      add :speaker, :string
      add :participant_limit, :integer
      add :year, :integer
      add :speaker_image, :string
      add :banner_image, :string

      timestamps()
    end

    create index(:workshops, [:slug], unique: true)
  end
end
