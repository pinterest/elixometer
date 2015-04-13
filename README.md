Elixometer
==========

A light wrapper around exometer.

Elixometer allows you to define metrics and subscribe them automatically
to the default reporter for your environment.

## Configuration

In one of your config files, set up an exometer reporter, and then register
it to elixometer like this:

       config(:elixometer, reporter: :exometer_report_tty,
       	    env: Mix.env,
       	    metric_prefix: "myapp")
Metrics are prepented with the metric_prefix, the type of metric and the environment name. 

## Metrics

Defining metrics in elixometer is substantially easier than in exometer. Instead of defining and then updating a metric, just update it. Also, instead of providing a list of atoms, a metric is named with a period separated bitstring. Presently, Elixometer supports timers, histograms, gauges, and counters.

Timings may also be defined by annotating a function with a @timed annotation. This annotation takes a key argument, which tells elixometer what key to use. You  can specify :auto and a key will be generated from the module name and method name.

Updating a metric is similarly easy:

```elixir
     
     defmodule ParentModule.MetricsTest do
       use Elixometer
        def counter_test(thingie) do
          update_counter("metrics_test.\#{thingie}.count", 1)
        end

        def timer_test do
          timed("metrics_test.timer_test.timings") do
            OtherModule.slow_method
          end
        end

        @timed(key: "timed.function") # key will be: prefix.dev.timers.timed.function
        def function_that_is_timed do
          OtherModule.slow_method
        end

        @timed(key: :auto) # The key will be "prefix.dev.timers.parent_module.metrics_test.another_timed_function"
        def another_timed_function do
          OtherModule.slow_method
        end
      end
```