defmodule Api.EmailsTest do
  use Api.ConnCase
  use Bamboo.Test

  alias Api.{Email, UserHelper}

  test "invite email" do
    user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    host = create_user(%{email: "host@example.com", password: "thisisapassword"})

    email = Email.invite_email(user, host)

    assert email.to == user
    assert email.subject == "#{UserHelper.display_name(host)} invited you to join a team in Make or Break"
  end
end