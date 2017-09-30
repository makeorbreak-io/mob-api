# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :api,
  ecto_repos: [Api.Repo],
  generators: [binary_id: true],
  # Use this tutorial to get a Slack token with client privileges
  # https://medium.com/@andrewarrow/how-to-get-slack-api-tokens-with-client-scope-e311856ebe9
  slack_token: System.get_env("SLACK_TOKEN"),
  # Maximum number of users each team is allowed to have
  team_user_limit: 4,
  # Library used to make external HTTP requests
  http_lib: HTTPoison,
  # Github API data
  github_token: System.get_env("GITHUB_TOKEN"),
  github_org: "portosummerofcode"



# Endpoint configuration
config :api, ApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: ApiWeb.ErrorView, accepts: ~w(json)]

# Elixir's Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Database configuration
config :api, Api.Repo,
  adapter: Ecto.Adapters.Postgres

# Guardian configuration
config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Api",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: System.get_env("SECRET_KEY_BASE"),
  serializer: ApiWeb.GuardianSerializer,
  permissions: %{
    admin: [:full],
    participant: [:full]
  }

# Bamboo configuration
config :api, Api.Mailer,
  adapter: Bamboo.LocalAdapter

# Sentry.io configuration
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env,
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
