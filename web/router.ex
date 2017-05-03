defmodule Api.Router do
  use Api.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/api", Api do
    pipe_through :api

    resources "/projects", ProjectController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]

    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end
end
