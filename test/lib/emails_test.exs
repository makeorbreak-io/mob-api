defmodule Api.EmailsTest do
  use Api.ConnCase
  use Bamboo.Test

  alias Api.{Email, UserHelper}

  test "invite email" do
    user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    host = create_user(%{email: "host@example.com", password: "thisisapassword"})

    email = Email.invite_email(user, host)

    assert email.to == user
    assert email.subject == "Join #{UserHelper.display_name(host)}'s team in this year's Make or Break!"
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