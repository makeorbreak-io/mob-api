defmodule Api.GraphQL.Queries.Competitions do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn}
  alias Api.GraphQL.Resolvers

  alias Api.Competitions

  object :competitions_queries do
    @desc "Default competition"
    field :default_competition, :competition do
      resolve fn _args, _info ->
        {:ok, Competitions.default_competition}
      end
    end
  end
end

