defmodule Elixometer.Mixfile do
  use Mix.Project

  @description """
  Elixometer is a light wrapper around exometer that defines and
  subscribes metrics automatically to the configured reporter.
  """

  @project_url "https://github.com/pinterest/elixometer"

  def project do
    [
      app: :elixometer,
      version: "1.5.0",
      elixir: ">= 1.7.0",
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.post": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env()),

      # Dialyzer
      dialyzer: [plt_add_deps: :transitive, plt_file: {:no_warn, "priv/plts/dialyzer.plt"}],

      # Docs
      name: "Elixometer",
      docs: [
        main: "Elixometer",
        source_ref: "master",
        source_url: @project_url
      ]
    ]
  end

  def application do
    [
      mod: {Elixometer.App, []},
      extra_applications: [:logger],
      env: default_config(Mix.env())
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
      {:exometer_core, "~> 1.6"},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.25", only: :dev},
      {:excoveralls, "~> 0.14", only: [:dev, :test]},
      {:pobox, "~> 1.2"}
    ]
  end

  defp package do
    [
      files: ["config", "lib", "mix.exs", "mix.lock", "CHANGELOG.md", "README.md", "LICENSE"],
      maintainers: ["Jon Parise", "Steve Cohen"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @project_url}
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end
end
