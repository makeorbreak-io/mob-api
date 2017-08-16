defmodule Api.User do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model
  alias Api.{Team, Invite, TeamMember}
  @derive {Poison.Encoder, only: [:id, :email, :first_name, :last_name]}

  alias Comeonin.Bcrypt

  @valid_attrs ~w(email first_name last_name password birthday employment_status college
                  company github_handle twitter_handle linkedin_url bio)

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :password_hash, :string
    field :birthday, :date
    field :employment_status, :string
    field :college, :string
    field :company, :string
    field :github_handle, :string
    field :twitter_handle, :string
    field :linkedin_url, :string
    field :bio, :string
    field :role, :string, default: "participant"
    timestamps()

    # Virtual fields
    field :password, :string, virtual: true

    # Associations
    has_one :team, Team
    has_many :invites, Invite, foreign_key: :host_id
    has_many :invitations, Invite, foreign_key: :invitee_id

    many_to_many :memberships, Team, join_through: TeamMember
  end

  @doc "Builds a changeset based on the `struct` and `params`."
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(~w(email)a)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def admin_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs ++ ["role"])
    |> validate_required(~w(email)a)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> validate_required(~w(password)a)
    |> validate_length(:password, min: 6)
    |> hash_password
  end

  defp hash_password(%{valid?: false} = changeset), do: changeset
  defp hash_password(%{valid?: true} = changeset) do
    hashed_password =
      changeset
      |> get_field(:password)
      |> Bcrypt.hashpwsalt()

    changeset
    |> put_change(:password_hash, hashed_password)
  end
end
