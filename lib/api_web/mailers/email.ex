defmodule ApiWeb.Email do
  use Bamboo.Phoenix, view: ApiWeb.EmailView
  alias ApiWeb.{UserHelper, LayoutView}

  def invite_email(recipient, host) do
    base_email()
    |> to(recipient)
    |> subject("Join #{UserHelper.display_name(host)}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{UserHelper.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, UserHelper.display_name(host))
    |> assign(:email, recipient)
    |> render("invite.html")
  end

  def invite_notification_email(recipient, host) do
    base_email()
    |> to(recipient)
    |> subject("Join #{UserHelper.display_name(host)}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{UserHelper.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, UserHelper.display_name(host))
    |> assign(:name, UserHelper.display_name(recipient))
    |> assign(:email, recipient.email)
    |> render("invite_notification.html")
  end

  def registration_email(recipient) do
    base_email()
    |> to(recipient)
    |> subject("Make or Break - You are almost there!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, UserHelper.display_name(recipient))
    |> render("registration.html")
  end

  def joined_hackathon_email(recipient, team) do
    base_email()
    |> to(recipient)
    |> subject("Welcome to the Make or Break hackathon!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to the Make or Break hackathon!")
    |> assign(:name, UserHelper.display_name(recipient))
    |> assign(:team_name, team.name)
    |> render("hackathon.html")
  end

  def joined_workshop_email(recipient, workshop) do
    base_email()
    |> to(recipient)
    |> subject("You have applied to #{workshop.name}")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "You have applied to #{workshop.name}")
    |> assign(:name, UserHelper.display_name(recipient))
    |> assign(:workshop, workshop)
    |> render("workshop.html")
  end

  def checkin_email(recipient) do
    base_email()
    |> to(recipient)
    |> subject("Welcome to Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, UserHelper.display_name(recipient))
    |> render("checkin.html")
  end

  def recover_password_email(recipient) do
    base_email()
    |> to(recipient)
    |> subject("Reset your MoB password.")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Reset your password")
    |> assign(:name, UserHelper.display_name(recipient))
    |> assign(:token, recipient.pwd_recovery_token)
    |> render("recover_password.html")
  end

  defp base_email do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from({"Porto Summer of Code", "info@portosummerofcode.com"})
  end
end