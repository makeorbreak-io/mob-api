defmodule Api.GraphQL.Mutations.Competitions do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Competitions

  object :competitions_mutations do
    @desc "Toggles competition check in status for user"
    field :toggle_user_checkin, :user do
      arg :user_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{user_id: user_id}, _info ->
        Competitions.toggle_checkin(Competitions.default_competition.id, user_id)
      end
    end
  end
end
