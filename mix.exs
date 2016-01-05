defmodule Elixometer.Mixfile do
  use Mix.Project

  def project do
    [app: :elixometer,
     version: "1.0.0",
     elixir: "~> 1.0",
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test],
     ]
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

  defp deps 
    [
        {:meck, github: "eproxus/meck", tag: "0.8.3", override: true, only: :test},
        {:edown, github: "uwiger/edown", tag: "0.7", override: true},
        {:lager, github: "basho/lager", tag: "2.1.0", override: true},
        {:exometer, github: "pspdfkit-labs/exometer"},
        {:netlink, github: "Feuerlabs/netlink", ref: "d6e7188e", override: true},
        {:excoveralls, github: "parroty/excoveralls", tag: "v0.4.3", override: true, only: :test}
    ]
  end
end
