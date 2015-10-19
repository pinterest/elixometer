defmodule Elixometer.Mixfile do
  use Mix.Project

  def project do
    [app: :elixometer,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [ mod: {Elixometer.App, []},
      applications: [:logger, :exometer]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
        {:meck, github: "eproxus/meck", tag: "0.8.2", override: true},
        {:edown, github: "uwiger/edown", tag: "0.7", override: true},
        {:lager, github: "basho/lager", tag: "2.0.3", override: true},
        {:exometer, github: "Feuerlabs/exometer", tag: "1.2"},
        {:netlink, github: "Feuerlabs/netlink", ref: "d6e7188e", override: true},
    ]
  end
end
