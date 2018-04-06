defmodule Api.Notifications.Emails do
  use Bamboo.Phoenix, view: ApiWeb.EmailView

  alias Api.Accounts.User
  alias ApiWeb.LayoutView

  def invite_email(recipient, host) do
    base_email(recipient)
    |> subject("Join #{User.display_name(host)}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{User.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, User.display_name(host))
    |> assign(:email, recipient)
    |> render("invite.html")
  end

  def invite_notification_email(recipient, host) do
    base_email(recipient)
    |> subject("Join #{host.name}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{User.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, User.display_name(host))
    |> assign(:name, User.display_name(recipient))
    |> assign(:email, recipient.email)
    |> render("invite_notification.html")
  end

  def registration_email(recipient) do
    base_email(recipient)
    |> subject("Make or Break - You are almost there!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("registration.html")
  end

  def joined_hackathon_email(recipient, team) do
    base_email(recipient)
    |> subject("You have applied to the Make or Break hackathon!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Your team's application is currently under review")
    |> assign(:name, User.display_name(recipient))
    |> assign(:team_name, team.name)
    |> render("hackathon.html")
  end

  def joined_workshop_email(recipient, workshop) do
    base_email(recipient)
    |> subject("You have applied to #{workshop.name}")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "You have applied to #{workshop.name}")
    |> assign(:name, User.display_name(recipient))
    |> assign(:workshop, workshop)
    |> render("workshop.html")
  end

  def checkin_email(recipient) do
    base_email(recipient)
    |> subject("Welcome to Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("checkin.html")
  end

  def recover_password_email(recipient) do
    base_email(recipient)
    |> subject("Reset your MoB password.")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Reset your password")
    |> assign(:name, User.display_name(recipient))
    |> assign(:token, recipient.pwd_recovery_token)
    |> render("recover_password.html")
  end

  def team_acceptance(recipient) do
    base_email(recipient)
    |> subject("Cheers, mate! You and your team are in Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("team_acceptance.html")
  end

  def not_applied(recipient) do
    base_email(recipient)
    |> subject("Apply to Make or Break hackathon until March 31")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:name, User.display_name(recipient))
    |> assign(:title, "Apply to Make or Break hackathon")
    |> render("not_applied.html")
  end

  def food_allergies(recipient) do
    base_email(recipient)
    |> subject("Make or Break — food restrictions inquiry")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:name, User.display_name(recipient))
    |> assign(:title, "Food restrictions inquiry")
    |> render("food_allergies.html")
  end

  defp base_email(recipient) do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from({"Make or Break", "info@makeorbreak.io"})
    |> to(recipient)
  end
end
