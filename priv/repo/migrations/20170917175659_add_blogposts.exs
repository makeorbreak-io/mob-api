defmodule ApiWeb.Repo.Migrations.AddBlogposts do
  use Ecto.Migration

  def change do
    execute("create type category as enum ('PSC14', 'PSC15', 'PSC16', 'MOB17')")

    create table(:blogposts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :slug, :string
      add :content, :text
      add :user_id, references(:users, type: :uuid)
      add :category, :category
      add :published_at, :utc_datetime, default: nil
      add :banner_image, :text

      timestamps()
    end

    create index(:blogposts, [:slug], unique: true)
  end
end
