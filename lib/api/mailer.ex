defmodule Api.Mailer do
  use Bamboo.Mailer, otp_app: :api
  alias ApiWeb.{UserHelper}

  defimpl Bamboo.Formatter, for: ApiWeb.User do
    def format_email_address(user, _opts) do
      {UserHelper.display_name(user), user.email}
    end
  end
end
