defmodule Api.Integrations.Medium do
  use Api.Web, :action

  @http Application.get_env(:api, :http_lib)

  def get_latest_posts(count) do
    url = "https://medium.com/@makeorbreak.io/latest?count=#{count}&format=json"

    with {:ok, response} <- @http.get(url), do: remove_prefix(response) |> Poison.decode!
  end

  defp remove_prefix(response) do
    String.replace_prefix(response.body, "])}while(1);</x>", "")
  end
end
