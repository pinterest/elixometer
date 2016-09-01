defmodule Elixometer.Mixfile do
  use Mix.Project

  def project do
    [app: :elixometer,
     version: "1.2.1",
     elixir: ">= 1.0.0",
     description: description,
     source_url: project_url,
     homepage_url: project_url,
     package: package,
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test],
     elixirc_paths: elixirc_paths(Mix.env),
     ]
  end

  def application do
     [mod: {Elixometer.App, []},
      applications: [:lager, :exometer_core, :pobox],
      erl_opts: [parse_transform: "lager_transform"],
      env: default_config(Mix.env)
     ]
  end

  def default_config(:test) do
     [update_frequency: 20]
  end

  def default_config(_) do
     [update_frequency: 1_000]
  end

  defp deps do
    [
      #lager 3.2.1 is needed for erl19 because of
      # https://github.com/basho/lager/pull/321
      {:lager, ">= 3.2.1", override: true},
      {:exometer_core, "~>1.4.0"},
      {:excoveralls, "~>0.5.4", only: :test},
      {:pobox, "~>1.0.2"}
    ]
  end

  defp description do
     """
     Elixometer is a light wrapper around exometer that defines and subscribes metrics automatically
to   the configured reporter.
     """
  end

  defp project_url do
     """
     https://github.com/pinterest/elixometer
     """
  end

  defp package do
     [files: ["config", "lib", "mix.exs", "mix.lock", "README.md", "LICENSE"],
      maintainers: ["Jon Parise", "Steve Cohen"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => project_url}
     ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

end
