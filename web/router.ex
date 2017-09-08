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
      resources "/teams", Admin.TeamController, except: [:new, :edit, :create]

      get "/stats", Admin.StatsController, :stats
      delete "/teams/:id/remove/:user_id", Admin.TeamController, :remove
      post "/teams/:id/disqualify", Admin.TeamController, :disqualify
      post "/invites/sync", Admin.InviteController, :sync
      post "/checkin/:id", Admin.UserController, :checkin
      delete "/checkin/:id", Admin.UserController, :remove_checkin
      post "/workshops/:id/checkin/:user_id", Admin.WorkshopController, :checkin
      delete "/workshops/:id/checkin/:user_id", Admin.WorkshopController, :remove_checkin
      post "/teams/:id/repo", Admin.TeamController, :create_repo
      post "/teams/:id/repo/add_users", Admin.TeamController, :add_users_to_repo
    end
  end
end
