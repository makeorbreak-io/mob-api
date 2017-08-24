use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, Api.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :api, Api.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.Postgres,
  url: "#{System.get_env("DB_URL")}-test"

# Bamboo configuration
config :api, Api.Mailer,
  adapter: Bamboo.TestAdapter

# Comeonin bcrypt test options
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1
