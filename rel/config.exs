# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
if false do
  Path.join(["rel", "plugins", "*.exs"])
  |> Path.wildcard()
  |> Enum.map(&Code.eval_file(&1))
end

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  set cookie: :meow
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: System.get_env("SECRET_KEY_BASE") |> String.to_atom
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :api do
  set version: current_version(:api)
  set applications: [
    :runtime_tools
  ]
end
