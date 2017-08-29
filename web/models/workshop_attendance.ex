defmodule Api.WorkshopAttendance do
  use Api.Web, :model

  alias Ecto.{Changeset}

  @primary_key false

  schema "users_workshops" do
    belongs_to :user, User
    belongs_to :workshop, Workshop
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, [:user_id, :workshop_id])
    |> Changeset.validate_required([:user_id, :workshop_id])
  end
end
