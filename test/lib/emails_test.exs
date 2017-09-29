defmodule ApiWeb.EmailsTest do
  use ApiWeb.ConnCase
  use Bamboo.Test

  alias ApiWeb.Email
  import Api.Accounts.User, only: [display_name: 1]

  test "invite email" do
    host = create_user(%{email: "host@example.com", password: "thisisapassword"})

    email = Email.invite_email("email@example.com", host)

    assert email.to == "email@example.com"
    assert email.subject == "Join #{display_name(host)}'s team in this year's Make or Break!"
  end

  test "registration email" do
    user = create_user(%{
      email: "user@example.com",
      password: "thisisapassword",
      first_name: "Random",
      last_name: "User"
      })

    email = Email.registration_email(user)

    assert email.to == user
    assert email.subject == "Make or Break - You are almost there!"
  end
end
