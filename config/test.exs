use Mix.Config

config(:exometer_core, report: [reporters: [{Elixometer.TestReporter, []}]])

config(
  :elixometer,
  update_frequency: 20,
  reporter: Elixometer.TestReporter,
  env: Mix.env(),
  metric_prefix: "elixometer"
)

# quiet down logging in test
config(:lager, handlers: [lager_console_backend: [level: :critical]])
