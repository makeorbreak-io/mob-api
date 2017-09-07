defmodule Api.User do
  @moduledoc """
    TODO: Write.
  """

  use Api.Web, :model
  alias Api.{EctoHelper, Crypto, Invite, TeamMember, Workshop, WorkshopAttendance}

  alias Comeonin.Bcrypt

  @valid_attrs ~w(email first_name last_name password birthday employment_status college
                  company github_handle twitter_handle linkedin_url bio tshirt_size
                  )
  @admin_attrs @valid_attrs ++ ~w(role checked_in)
  @required_attrs ~w(email voter_identity)a

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
    field :tshirt_size, :string
    field :checked_in, :boolean, default: false
    field :voter_identity, :string
    timestamps()

    # Virtual fields
    field :password, :string, virtual: true

    # Associations
    has_many :invites, Invite, foreign_key: :host_id, on_delete: :delete_all
    has_many :invitations, Invite, foreign_key: :invitee_id, on_delete: :delete_all
    has_many :teams, TeamMember, foreign_key: :user_id, on_delete: :delete_all

    many_to_many :workshops, Workshop, join_through: WorkshopAttendance, on_delete: :delete_all
  end

  def changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def participant_changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def admin_changeset(struct, params \\ %{}), do: _cs(struct, params, @admin_attrs)
  defp _cs(struct, params, attrs) do
    struct
    |> cast(params, attrs)
    |> EctoHelper.if_missing(:voter_identity, Crypto.random_hmac())
    |> validate_required(@required_attrs)
    |> unique_constraint(:voter_identity)
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
