defmodule ApiWeb.Router do
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

  scope "/api", ApiWeb do
    pipe_through :api

    resources "/teams", TeamController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    resources "/invites", InviteController, except: [:new, :edit, :update]
    resources "/workshops", WorkshopController, only: [:index, :show]

    get "/me", SessionController, :me
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete

    post "/invites/invite_to_slack", InviteController, :invite_to_slack
    put "/invites/:id/accept", InviteController, :accept

    delete "/teams/:id/remove/:user_id", TeamController, :remove

    post "/workshops/:id/join", WorkshopController, :join
    delete "/workshops/:id/leave", WorkshopController, :leave

    get "/voting/info_begin", VotingController, :info_begin
    get "/voting/info_end", VotingController, :info_end
    get "/voting/vote", VotingController, :get_votes
    post "/voting/vote", VotingController, :upsert_votes

    get "/latest_posts", PresentationController, :get_latest_posts

    get "/users/password/get_token", UserController, :get_token
    post "/users/password/recover", UserController, :recover_password

    scope "/admin", as: :admin do
      resources "/users", Admin.UserController, except: [:new, :edit, :create]
      resources "/workshops", Admin.WorkshopController, except: [:new, :edit]
      resources "/teams", Admin.TeamController, except: [:new, :edit, :create]

      get "/stats", Admin.StatsController, :stats

      post "/teams/:id/disqualify", Admin.TeamController, :disqualify
      post "/teams/:id/repo", Admin.TeamController, :create_repo
      post "/teams/:id/repo/add_users", Admin.TeamController, :add_users_to_repo
      delete "/teams/:id/remove/:user_id", Admin.TeamController, :remove

      post "/checkin/:id", Admin.UserController, :checkin
      delete "/checkin/:id", Admin.UserController, :remove_checkin

      post "/workshops/:id/checkin/:user_id", Admin.WorkshopController, :checkin
      delete "/workshops/:id/checkin/:user_id", Admin.WorkshopController, :remove_checkin

      get "/competition/status", Admin.CompetitionController, :status
      post "/competition/start_voting", Admin.CompetitionController, :start_voting
      post "/competition/end_voting", Admin.CompetitionController, :end_voting

      get "/paper_vote/:id", Admin.PaperVoteController, :show
      post "/paper_vote", Admin.PaperVoteController, :create
      post "/paper_vote/:id/redeem", Admin.PaperVoteController, :redeem
      post "/paper_vote/:id/annul", Admin.PaperVoteController, :annul
    end
  end
end
