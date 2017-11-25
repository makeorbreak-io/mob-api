defmodule Api.Mixfile do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "1.0.0",
      elixir: "~> 1.5",  # Remember to change .exenv-version
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_deps: :transitive,
        ignore_warnings: "dialyzer.ignore-warnings",
      ],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Api.Application, []},
      extra_applications: [
        :bamboo,
        :comeonin,
        :cors_plug,
        :cowboy,
        :elixir_make,
        :guardian,
        :httpoison,
        :logger,
        :markus,
        :phoenix,
        :phoenix_ecto,
        :phoenix_html,
        :postgrex,
        :runtime_tools,
        :sentry,
        :tentacat,

        :edeliver,  # MUST be the last
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 0.8"},
      {:comeonin, "~> 3.0"},
      {:cors_plug, "~> 1.2"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, "~> 1.4"},
      {:edeliver, "~> 1.4.4"},
      {:excoveralls, "~> 0.7", only: :test},
      {:guardian, "~> 0.14"},
      {:httpoison, "~> 0.13"},
      {:markus, "~> 0.3.0"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:poison, ">= 2.2.0"},
      {:postgrex, "~> 0.13.3"},
      {:sentry, "~> 5.0.1"},
      {:tentacat, "~> 0.6.2"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": [
        "ecto.drop",
        "ecto.setup"
      ],
      "test": [
        "ecto.create --quiet",
        "ecto.migrate",
        "credo --strict",
        "coveralls",

      ],
      "server": [
        "phx.server",
      ],
      "sentry_recompile": [
        "clean", "compile",
      ],
      "deploy": [
        "edeliver build release",
        "edeliver deploy release production",
        "edeliver restart production",
        "edeliver migrate production",
      ],
    ]
  end
end
