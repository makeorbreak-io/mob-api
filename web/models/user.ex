defmodule Api.User do
  use Api.Web, :model
  @derive {Poison.Encoder, only: [:id, :email, :first_name, :last_name]}

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :password_hash, :string

    timestamps()

    # Virtual fields
    field :password, :string, virtual: true

    # Relationships
    has_one :project, Api.Project
  end

  @doc "Builds a changeset based on the `struct` and `params`."
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(email first_name last_name))
    |> validate_required(~w(email)a)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> cast(params, ~w(password))
    |> validate_required(~w(password)a)
    |> validate_length(:password, min: 6)
    |> hash_password
  end

  defp hash_password(%{valid?: false} = changeset), do: changeset
  defp hash_password(%{valid?: true} = changeset) do
    hashed_password =
      changeset
      |> get_field(:password)
      |> Comeonin.Bcrypt.hashpwsalt()

    changeset
    |> put_change(:password_hash, hashed_password)
  end
end
