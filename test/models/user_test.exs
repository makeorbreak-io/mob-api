defmodule ApiWeb.UserTest do
  use ApiWeb.ModelCase

  alias Api.{Accounts, Accounts.User}
  alias ApiWeb.TeamActions

  @valid_attrs %{
    email: "johndoe@example.com",
    first_name: "john",
    last_name: "doe",
    password: "thisisapassword"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset, email too short " do
    changeset = User.changeset(
      %User{}, Map.put(@valid_attrs, :email, "")
    )
    refute changeset.valid?
  end

  test "changeset, email invalid format" do
    changeset = User.changeset(
      %User{}, Map.put(@valid_attrs, :email, "foo.com")
    )
    refute changeset.valid?
  end

  test "registration_changeset, valid password" do
    changeset = User.registration_changeset(%User{}, @valid_attrs)
    assert changeset.changes.password_hash
    assert changeset.valid?
  end

  test "registration_changeset, password too short" do
    changeset = User.registration_changeset(
      %User{}, Map.put(@valid_attrs, :password, "12345")
    )
    refute changeset.valid?
  end

  test "able_to_vote not in a team" do
    create_user()

    assert User.able_to_vote() |> Repo.all == []
  end

  test "able_to_vote not checked in" do
    create_team(create_user())

    assert User.able_to_vote() |> Repo.all == []
  end

  test "able_to_vote checked in" do
    u = create_user()
    create_team(u)
    Accounts.toggle_checkin(u.id, true)
    u = Repo.get!(User, u.id)

    assert User.able_to_vote() |> Repo.all == [u]
  end

  test "able_to_vote disqualified" do
    u = create_user()
    t = create_team(u)
    Accounts.toggle_checkin(u.id, true)

    TeamActions.disqualify(t.id, create_admin())

    assert User.able_to_vote() |> Repo.all == []
  end

  test "able_to_vote disqualified later" do
    u = create_user()
    t = create_team(u)
    Accounts.toggle_checkin(u.id, true)

    TeamActions.disqualify(t.id, create_admin())

    {:ok, past} = DateTime.from_unix(DateTime.to_unix(DateTime.utc_now) - 10)
    assert User.able_to_vote(past) |> Repo.all == [Repo.get!(User, u.id)]
  end
end
