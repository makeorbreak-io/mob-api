defmodule ApiWeb.UserHelper do
  # display name: "#{first_name} ${last_name}", or, if missing, email address before the "@" sign
  def display_name(%{first_name: nil, last_name: nil, email: email}), do: List.first(String.split(email, "@", parts: 2))
  def display_name(%{first_name: first_name, last_name: nil}), do: "#{first_name}"
  def display_name(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"

  # gravatar hash
  def gravatar_hash(%{email: email}), do: :crypto.hash(:md5, String.trim(email)) |> Base.encode16(case: :lower)

  # generate password recovery token
  def generate_token(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def calculate_token_expiration do
    :erlang.universaltime
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.+(30 * 60)
    |> DateTime.from_unix!
  end
end
