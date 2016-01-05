Elixometer
==========

[![Build Status](https://travis-ci.org/pinterest/elixometer.svg?branch=master)](https://travis-ci.org/pinterest/elixometer)
[![Coverage Status](https://coveralls.io/repos/pinterest/elixometer/badge.svg?branch=&service=github)](https://coveralls.io/github/pinterest/elixometer?branch=master)

A light wrapper around exometer.

Elixometer allows you to define metrics and subscribe them automatically
to the default reporter for your environment.

## Installation
Add the following to your dependencies in mix.exs:

```elixir
{:elixometer, github: "pinterest/elixometer"}
```

Then, add `:elixometer` to your applications. That's it!

## Configuration

In one of your config files, set up an exometer reporter, and then register
it to elixometer like this:

```elixir
       config(:exometer, report: [reporters: [{:exometer_report_tty, []}]])
       config(:elixometer, reporter: :exometer_report_tty,
       	    env: Mix.env,
       	    metric_prefix: "myapp")
```
Metrics are prepended with the `metric_prefix`, the type of metric and the environment name.

The optional `update_frequency` key of the :elixometer config controls the interval between reports. By default this is set to `1000` ms in the `dev` environment and `20` ms in the `test` environment.

## Metrics

Defining metrics in elixometer is substantially easier than in exometer. Instead of defining and then updating a metric, just update it. Also, instead of providing a list of atoms, a metric is named with a period separated bitstring. Presently, Elixometer supports timers, histograms, gauges, counters, and spirals.

Timings may also be defined by annotating a function with a @timed annotation. This annotation takes a key argument, which tells elixometer what key to use. You  can specify `:auto` and a key will be generated from the module name and method name.

Updating a metric is similarly easy:

```elixir

     defmodule ParentModule.MetricsTest do
        use Elixometer

        # Updating a counter
        def counter_test(thingie) do
          update_counter("metrics_test.\#{thingie}.count", 1)
        end

        # Updating a spiral
        def spiral_test(thingie) do
          update_spiral("metrics_test.\#{thingie}.qps", 1)
        end

        # Timing a block of code in a function
        def timer_test do
          timed("metrics_test.timer_test.timings") do
            OtherModule.slow_method
          end
        end

        # Timing a function. The metric name will be [:timed, :function]
        @timed(key: "timed.function") # key will be: prefix.dev.timers.timed.function
        def function_that_is_timed do
          OtherModule.slow_method
        end

       # Timing a function with an auto generated key
       # The key will be "<prefix>.<env>.timers.parent_module.metrics_test.another_timed_function"
       # If the env is prod, the environment is omitted from the key
        @timed(key: :auto)
        def another_timed_function do
          OtherModule.slow_method
        end
      end
```
