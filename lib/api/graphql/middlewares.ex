defmodule Api.GraphQL.Middleware do
  alias Absinthe.Resolution

  alias Api.Accounts.User

  defmodule RequireAuthn do
    @behaviour Absinthe.Middleware

    def call(%{context: %{current_user: %User{}}} = resolution, _config) do
      resolution
    end

    def call(%{context: %{current_user: nil}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "using this field requires authentication",
      }})
    end
  end

  defmodule RequireAdmin do
    @behaviour Absinthe.Middleware

    def call(%{context: %{current_user: %User{role: "admin"}}} = resolution, _config) do
      resolution
    end

    def call(%{context: %{current_user: %User{role: "participant"}}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "you do not have permission to access this field",
      }})
    end

    def call(%{context: %{current_user: nil}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "using this field requires authentication",
      }})
    end
  end

  defmodule UserToJWT do
    @behaviour Absinthe.Middleware

    def call(%{value: %User{} = user} = res, _config) do
      res
      |> Resolution.put_result(
        with {:ok, jwt, _full_claims} <- Guardian.encode_and_sign(user, :api)
        do
          {:ok, jwt}
        end
      )
    end

    def call(res, _config), do: res
  end

end
