defmodule Api.UpgradeCallbacks do
  import Gatling.Bash

  def before_upgrade_service(env) do
    bash("mix", ~w[ecto.migrate], cd: env.build_dir)
  end
end
