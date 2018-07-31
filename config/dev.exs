use Mix.Config

config :exometer_core, report: [reporters: []]

config :lager,
  log_root: 'log',
  handlers: [
    lager_console_backend: [level: :info],
    lager_file_backend: [
      file: 'error.log',
      level: :error,
      formatter: :lager_default_formatter,
      formatter_config: [:date, " ", :time, " [", :severity, "]", :pid, " ", :message, "\n"]
    ],
    lager_file_backend: [file: 'console.log', level: :debug]
  ]

config :elixometer,
  reporter: :exometer_report_tty,
  update_frequency: 1000,
  env: Mix.env(),
  metric_prefix: "elixometer"
