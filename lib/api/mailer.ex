defmodule Api.Mailer do
  use Bamboo.Mailer, otp_app: :api

  alias Api.Accounts.User
  import Api.Accounts.User, only: [display_name: 1]

  defimpl Bamboo.Formatter, for: User do
    def format_email_address(user, _opts) do
      {display_name(user), user.email}
    end
  end
end
