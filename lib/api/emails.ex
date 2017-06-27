defmodule Api.Email do
  import Bamboo.Email
  alias Api.UserHelper

  def invite_email(recipient, host) do
    base_email
    |> to(recipient)
    |> subject("#{UserHelper.display_name(host)} invited you to join a team in Make or Break")
    |> html_body("
      <p>#{UserHelper.display_name(host)} is assembling a team for this year Make or Break competition and he wants your help.</p>
      <a href='http://makeorbreak.portosummerofcode.com'>Sign up now</a>
    ")
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email
    |> from("info@portosummerofcode.com")
  end
end