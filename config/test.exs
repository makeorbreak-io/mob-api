use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, ApiWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :api, ApiWeb.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.Postgres,
  url: "#{System.get_env("DB_URL")}-test"

config :api,
  slack_token: "DUMMY-TOKEN",
  http_lib: FakeHTTPoison

# Bamboo configuration
config :api, ApiWeb.Mailer,
  adapter: Bamboo.TestAdapter

# Comeonin bcrypt test options
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1
