# API

## Setup guide
To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Add the necessary variables to your environment
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Start Phoenix endpoint with `mix server`

## Environment Variables

Use your preferred method to add the following variables to your environment.
You can find an example env file you can source in `share/env/env`

| Variable           | Description             | Environments
| ------------------ | ----------------------- | ------------
| DB_URL             | Postgresql database url | All
| SECRET_KEY_BASE    | Secret key base         | All
| MAILGUN_API_KEY    | Mailgun API credentials | Prod
| MAILGUN_API_DOMAIN | Mailgun API credentials | Prod
| HOST               | Server url              | Prod
| SENTRY_DSN         | Sentry.io project url   | Prod
| SLACK_TOKEN        | Slack API access token  | Prod
| GITHUB_TOKEN       | Github API access token | All
