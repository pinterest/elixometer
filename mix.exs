defmodule Elixometer.Mixfile do
  use Mix.Project

  def project do
    [app: :elixometer,
     version: "1.0.0",
     elixir: "~> 1.0",
     description: description,
     source_url: project_url,
     homepage_url: project_url,
     package: package,
     deps: deps]
  end

  def application do
    [ mod: {Elixometer.App, []},
      applications: [:logger, :exometer],
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
        {:meck, "~> 0.8.3"},
        {:edown, github: "uwiger/edown", tag: "0.7", override: true},
        {:lager, github: "basho/lager", tag: "2.1.0", override: true},
        {:exometer, github: "pspdfkit-labs/exometer"},
        {:netlink, github: "Feuerlabs/netlink", ref: "d6e7188e", override: true},
    ]
  end

  defp description do
    """
    Elixometer is a light wrapper around exometer that defines and subscribes metrics automatically
to the configured reporter.
    """
  end

  defp project_url do
    """
    https://github.com/pinterest/elixometer
    """
  end

  defp package do
    [files: ["config", "lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jon Parise", "Steve Cohen"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => project_url}]
  end
end
