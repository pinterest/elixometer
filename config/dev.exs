use Mix.Config

config :exometer_core, report: [reporters: []]

config :elixometer,
  reporter: :exometer_report_tty,
  update_frequency: 1000,
  env: Mix.env(),
  metric_prefix: "elixometer"

config :logger,
  level: :info
