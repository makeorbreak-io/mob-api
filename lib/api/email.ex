defmodule Api.Email do
  use Bamboo.Phoenix, view: Api.EmailView
  alias Api.UserHelper

  def invite_email(recipient, host) do
    base_email
    |> to(recipient)
    |> subject("Join #{UserHelper.display_name(host)}'s team in this year's Make or Break!")
    |> put_html_layout({Api.LayoutView, "email.html"})
    |> assign(:title, "Join #{UserHelper.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, UserHelper.display_name(host))
    |> render("invite.html")
  end

  def registration_email(recipient) do
    base_email
    |> to(recipient)
    |> subject("Make or Break - You are almost there!")
    |> put_html_layout({Api.LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, UserHelper.display_name(recipient))
    |> render("registration.html")
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email
    |> from("info@portosummerofcode.com")
  end
end