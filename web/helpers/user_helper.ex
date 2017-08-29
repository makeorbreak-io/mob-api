defmodule Api.UserHelper do
  # display name: "#{first_name} ${last_name}", or, if missing, email address before the "@" sign
  def display_name(%{first_name: nil, last_name: nil, email: email}), do: List.first(String.split(email, "@", parts: 2))
  def display_name(%{first_name: first_name, last_name: nil}), do: "#{first_name}"
  def display_name(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"

  # gravatar hash
  def gravatar_hash(%{email: email}), do: :crypto.hash(:md5, String.trim(email)) |> Base.encode16(case: :lower)
end
