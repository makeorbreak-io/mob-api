defmodule Api.GraphQL.Plug.AbsintheContext do
  @behaviour Plug

  import Plug.Conn

  alias Guardian.Plug, as: GuardianPlug

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_private(
      :absinthe,
      %{context:
        %{
          current_user: GuardianPlug.current_resource(conn)
        }
      }
    )
  end
end
