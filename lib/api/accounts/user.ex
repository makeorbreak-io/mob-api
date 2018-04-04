defmodule Api.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Repo
  alias Api.Competitions.Attendance
  alias Api.{Workshops.Workshop, Workshops.Attendance}
  alias Api.{Teams.Invite, Teams.Membership}
  alias Api.AICompetition.Bot
  alias Comeonin.Bcrypt

  @valid_attrs ~w(
    email
    name
    password
    birthday
    employment_status
    college
    company
    github_handle
    twitter_handle
    linkedin_url
    bio
    tshirt_size
    pwd_recovery_token
    pwd_recovery_token_expiration
  )a

  @admin_attrs @valid_attrs ++ ~w(
    role
  )a

  @required_attrs ~w(
    email
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
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
    field :pwd_recovery_token, :string
    field :pwd_recovery_token_expiration, :utc_datetime, default: nil

    timestamps()

    # Virtual fields
    field :password, :string, virtual: true

    # Associations
    has_many :invites, Invite, foreign_key: :host_id, on_delete: :delete_all
    has_many :invitations, Invite, foreign_key: :invitee_id, on_delete: :delete_all
    has_many :memberships, Membership, foreign_key: :user_id, on_delete: :delete_all
    has_many :teams, through: [:memberships, :team]
    has_many :ai_competition_bots, Bot
    has_many :attendances, Attendance, foreign_key: :attendee

    many_to_many :workshops, Workshop, join_through: Attendance, on_delete: :delete_all
  end

  def changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def participant_changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def admin_changeset(struct, params \\ %{}), do: _cs(struct, params, @admin_attrs)
  defp _cs(struct, params, attrs) do
    struct
    |> cast(params, attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:password_recovery_token)
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

  # gravatar hash
  def gravatar_hash(%{email: email}),
    do: :crypto.hash(:md5, String.trim(email)) |> Base.encode16(case: :lower)

  def display_name(%{name: name, email: email}) do
    name || (email |> String.split("@") |> Enum.at(0))
  end

  def can_apply_to_workshops(user) do
    user = Repo.preload(user, [:workshops, :teams])

    (
      Enum.any?(user.teams, fn team -> team.applied == true && team.accepted == true end) &&
      Enum.count(user.workshops, fn(w) -> w.year == DateTime.utc_now.year end) < 2
    ) || true
  end

  def can_apply_to_hackathon(user) do
    user = Repo.preload(user, :workshops)

    Enum.count(user.workshops, fn(w) -> w.year == DateTime.utc_now.year end) <= 2
  end

  # generate password recovery token
  def generate_token(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def calculate_token_expiration do
    :erlang.universaltime
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.+(30 * 60)
    |> DateTime.from_unix!
  end

  # def able_to_vote(at \\ nil) do
  #   at = at || DateTime.utc_now

  #   from(
  #     u in User,
  #     left_join: tm in assoc(u, :teams),
  #     left_join: t in assoc(tm, :team),
  #     where: u.role == "participant",
  #     where: is_nil(t.disqualified_at) or t.disqualified_at > ^at,
  #   )
  # end
end
