defmodule Api.Router do
  use Api.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end

  scope "/api", Api do
    pipe_through :api

    resources "/projects", ProjectController, except: [:new, :edit]
    resources "/teams", TeamController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    resources "/invites", InviteController, except: [:new, :edit, :update]
    resources "/workshops", WorkshopController, only: [:index, :show]

    get "/me", SessionController, :me
    post "/login", SessionController, :create
    put "/invites/:id/accept", InviteController, :accept
    post "/invites/invite_to_slack", InviteController, :invite_to_slack
    delete "/logout", SessionController, :delete
    delete "/teams/:id/remove/:user_id", TeamController, :remove
    post "/workshops/:id/join", WorkshopController, :join
    delete "/workshops/:id/leave", WorkshopController, :leave

    scope "/admin", as: :admin do
      resources "/users", Admin.UserController, except: [:new, :edit, :create]
      resources "/workshops", Admin.WorkshopController, except: [:new, :edit]

      get "/stats", Admin.StatsController, :stats
    end
  end
end
