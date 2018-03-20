defmodule ApiWeb.Router do
  use Api.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  pipeline :graphql do
    plug :accepts, ["json", "graphql"]
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
    plug Api.GraphQL.Plug.AbsintheContext
  end

  scope "/graphql" do
    pipe_through :graphql

    if Mix.env == :dev do
      forward "/i", Absinthe.Plug.GraphiQL, schema: Api.GraphQL.Schema
    end

    forward "/", Absinthe.Plug, schema: Api.GraphQL.Schema
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ApiWeb do
    pipe_through :api

    post "/invites/invite_to_slack", InviteController, :invite_to_slack

    get "/users/password/get_token", UserController, :get_token
    post "/users/password/recover", UserController, :recover_password

    post "/bots/:id", BotsController, :callback
    post "/games/:id", GamesController, :callback
  end
end
