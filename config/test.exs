use Mix.Config

config(:exometer_core, report: [reporters: [{Elixometer.TestReporter, []}]])

config(:elixometer, update_frequency: 20,
       reporter: Elixometer.TestReporter,
       env: Mix.env,
       metric_prefix: "elixometer")
