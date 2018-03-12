defmodule Api.AccountsTest do
  use Api.DataCase

  alias Api.Accounts
  alias Api.Accounts.User
  alias Comeonin.Bcrypt
  alias Guardian

  @valid_attrs %{
    email: "johndoe@example.com",
    first_name: "john Doe",
    password: "thisisapassword"
  }
  @invalid_attrs %{email: "no at sign"}

  setup do
    u1 = create_user() |> Map.replace(:password, nil)

    {:ok, %{u1: u1}}
  end

  test "list users", %{u1: u1} do
    u2 = create_user() |> Map.replace(:password, nil)
    users = Accounts.list_users()

    assert users == [u1, u2]
    assert length(users) == 2
  end

  test "get user", %{u1: u1} do
    assert Accounts.get_user(u1.id) == u1
  end

  test "get nonexistent user" do
    assert Accounts.get_user("11111111-1111-1111-1111-111111111111") == nil
  end

  test "create valid user" do
    {:ok, _, user} = Accounts.create_user(@valid_attrs)

    assert Repo.get(User, user.id)
  end

  test "create invalid user" do
    {:error, changeset} = Accounts.create_user(@invalid_attrs)

    assert changeset.valid? == false
  end

  test "update user with valid data", %{u1: u1} do
    {:ok, _} = Accounts.update_user(u1, u1.id, @valid_attrs)

    assert Repo.get_by(User, email: "johndoe@example.com")
  end

  test "update user with invalid data", %{u1: u1} do
    {:error, changeset} = Accounts.update_user(u1, u1.id, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "update user if user not authorized", %{u1: u1} do
    u2 = create_user()

    result = Accounts.update_user(u2, u1.id, @valid_attrs)
    assert result == {:unauthorized, :unauthorized}
  end

  test "update any user with valid data", %{u1: u1} do
    {:ok, _} = Accounts.update_any_user(u1.id, @valid_attrs)

    assert Repo.get_by(User, email: "johndoe@example.com")
  end

  test "update any user with invalid data", %{u1: u1} do
    {:error, changeset} = Accounts.update_any_user(u1.id, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "delete user", %{u1: u1} do
    {:ok, user} = Accounts.delete_user(u1, u1.id)

    refute Repo.get_by(User, email: user.email)
  end

  test "delete user if user not authorized", %{u1: u1} do
    u2 = create_user()

    result = Accounts.delete_user(u2, u1.id)
    assert result == {:unauthorized, :unauthorized}
  end

  test "delete any user", %{u1: u1} do
    {:ok, user} = Accounts.delete_any_user(u1.id)

    refute Repo.get_by(User, email: user.email)
  end

  test "get password token with a valid email", %{u1: u1} do
    {:ok, user} = Accounts.get_pwd_token(u1.email)

    assert user.pwd_recovery_token != nil
    assert user.pwd_recovery_token_expiration != nil
  end

  test "get pwassword token with an invalid email" do
    assert :user_not_found = Accounts.get_pwd_token("invalid@email.com")
  end

  test "recover password", %{u1: u1} do
    {:ok, u2} = Accounts.get_pwd_token(u1.email)

    {:ok, u3} = Accounts.recover_password(u2.pwd_recovery_token, "newpassword")

    assert Bcrypt.checkpw("newpassword", u3.password_hash)
  end

  test "recover password if token doesn't exist" do
    assert :invalid_token == Accounts.recover_password(User.generate_token(), "newpassword")
  end

  test "recover password if token is expired" do
    u1 = create_user(%{
      pwd_recovery_token: User.generate_token(),
      pwd_recovery_token_expiration: Ecto.DateTime.to_iso8601(%Ecto.DateTime{
        year: 2017,
        month: 5,
        day: 10,
        hour: 10,
        min: 14,
        sec: 15}),
      password: "thisisapassword"
    })

    assert :expired_token == Accounts.recover_password(u1.pwd_recovery_token, "newpassword")
  end

  test "create session" do
    u1 = create_user(@valid_attrs)
    {:ok, jwt, u2} = Accounts.create_session("johndoe@example.com", "thisisapassword")

    refute is_nil(jwt)
    assert u2.email == u1.email
  end

  test "create session with invalid email" do
    assert :wrong_credentials == Accounts.create_session("invalid@email.com", "newpassword")
  end

  test "revoke session", %{u1: u1} do
    {:ok, jwt, _} = Accounts.create_session(u1.email, "thisisapassword")

    assert :ok == Accounts.delete_session(jwt)
  end
end
