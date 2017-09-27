defmodule ApiWeb.WorkshopAttendance do
  use Api.Web, :model

  alias ApiWeb.{User, Workshop}

  @primary_key false

  @valid_attrs ~w(
    user_id
    workshop_id
    checked_in
  )a

  @required_attrs ~w(
    user_id
    workshop_id
  )a

  schema "users_workshops" do
    field :checked_in, :boolean, default: false

    belongs_to :user, User
    belongs_to :workshop, Workshop
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
  end
end
