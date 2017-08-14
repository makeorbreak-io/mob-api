defmodule Api.Router do
  use Api.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  scope "/api", Api do
    pipe_through :api

    resources "/projects", ProjectController, except: [:new, :edit]
    resources "/teams", TeamController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    resources "/invites", InviteController, except: [:new, :edit]

    get "/me", SessionController, :me
    post "/login", SessionController, :create
    put "/invites/:id/accept", InviteController, :accept
    delete "/logout", SessionController, :delete
    delete "/teams/:id/remove/:user_id", TeamController, :remove

    scope "/admin", as: :admin do
      resources "/users", Admin.UserController, only: [:index, :show]
    end
  end
end
