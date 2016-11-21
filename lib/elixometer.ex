defmodule Elixometer do
  @moduledoc ~S"""
  A light wrapper around exometer.

  Elixometer allows you to define metrics and subscribe them automatically
  to the default reporter for your environment.

  ## Configuration

  In one of your config files, set up an exometer reporter, and then register
  it to elixometer like this:

       config(:elixometer, reporter: :exometer_report_tty)

  ## Metrics

  Defining metrics in elixometer is substantially easier than in exometer.
  Instead of defining and then updating a metric, just update it. Also, instead
  of providing a list of atoms, a metric is named with a period separated
  bitstring. Presently, Elixometer supports timers, histograms, gauges,
  and counters.

  Timings may also be defined by annotating a function with a @timed annotation.
  This annotation takes a key argument, which tells elixometer what key to use. You
  can specify :auto and a key will be generated from the module name and method name.

  Updating a metric is similarly easy:

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

         @timed(key: "timed.function")
         def function_that_is_timed do
           OtherModule.slow_method
         end

         @timed(key: :auto) # The key will be "parent_module.metrics_test.another_timed_function"
         def another_timed_function do
           OtherModule.slow_method
         end
       end

  """

  defmodule App do
    use Application

    def start(_type, _args_) do
      Elixometer.Supervisor.start_link
    end
  end

  defmodule Config do
    defstruct table_name: nil, counters: Map.new
  end

  defmodule Timer do
    defstruct method_name: nil, key: nil, units: :micros, args: nil, guards: nil, body: nil
  end

  @elixometer_table :elixometer
  alias Elixometer.Updater
  import Elixometer.Utils
  use GenServer


  defmacro __using__(_mod) do

    quote do
      import Elixometer
      Module.register_attribute(__MODULE__, :elixometer_timers, accumulate: true)
      @before_compile Elixometer
      @on_definition Elixometer
    end
  end

  def __on_definition__(env, _kind, name, args, guards, body) do
    mod = env.module
    timer_info = Module.get_attribute(mod, :timed)

    if timer_info do
      key = case timer_info[:key] do
              :auto ->
                # Convert a fully qualified module to an underscored representation.
                # Module.SubModule.SubSubModule will become
                # module.sub_module.sub_sub_module
                prefix = mod
                |> inspect
                |> String.replace(~r/([a-z])([A-Z])/, ~S"\1_\2")
                |> String.downcase

                "#{prefix}.#{name}"

              other -> other
            end

      units = timer_info[:units] || :micros
      Module.put_attribute(mod, :elixometer_timers,
                           %Timer{method_name: name,
                                  args: args,
                                  guards: guards,
                                  body: body,
                                  units: units,
                                  key: key})

      Module.delete_attribute(mod, :timed)
    end
  end

  defp build_timer_body(timer_data=%Timer{}) do
    quote do
      timed(unquote(timer_data.key), unquote(timer_data.units)) do
        unquote(timer_data.body)
      end
    end
  end

  defmacro __before_compile__(env) do
    mod = env.module
    timers = Module.get_attribute(mod, :elixometer_timers)
    timed_methods = timers
    |> Enum.reverse
    |> Enum.map(
        fn(timer_data=%Timer{}) ->
          Module.make_overridable(mod,
                                  [{timer_data.method_name, length(timer_data.args)}])
          body = build_timer_body(timer_data)
          if length(timer_data.guards) > 0 do
            quote do
              def unquote(timer_data.method_name)(unquote_splicing(timer_data.args)) when unquote_splicing(timer_data.guards) do
                unquote(body)
              end
            end

          else
            quote do
              def unquote(timer_data.method_name)(unquote_splicing(timer_data.args))  do
                unquote(body)
              end
            end
          end
        end)

    quote do
      unquote_splicing(timed_methods)
    end
  end

  def init(:ok) do
    table_name = :ets.new(@elixometer_table, [:set, :named_table, read_concurrency: true])
    :timer.send_interval(250, :tick)

    {:ok, %Config{table_name: table_name}}
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_metric_value(metric_name) do
    metric_name
    |> to_atom_list
    |> :exometer.get_value
  end

  def get_metric_value(metric_name, data_point) do
    metric_val = metric_name
    |> to_atom_list
    |> :exometer.get_value(data_point)

    case metric_val do
      {:ok, metric} -> {:ok, metric[data_point]}
      r = {:error, _reason} -> r
    end
  end

  @doc """
  Updates a histogram with a new value. If the metric doesn't exist, a new metric
  is created and subscribed to.
  """
  def update_histogram(name, delta, aggregate_seconds\\60, truncate\\true) when is_bitstring(name) do
    Updater.histogram(name, delta, aggregate_seconds, truncate)
  end

  @doc """
  Updates and alternately creates spiral metric. A spiral metric is a metric maintains a series
  of internal slots that 'age out' and are replaced by newer values. This is useful for
  maintaining QPS stats.
  """
  def update_spiral(name, delta, opts \\ [time_span: :timer.seconds(60), slot_period: 1000]) do
    Updater.spiral(name, delta, opts)
  end

  @doc """
  Updates a counter metric. If the metric doesn't exist, the metric is created
  and the metric is subscribed to the default reporter.

  If the value of the `:reset_seconds` option is greater than zero, the counter will be reset
  automatically at the specified interval.
  """
  def update_counter(name, delta, [reset_seconds: secs] \\ [reset_seconds: nil]) when is_bitstring(name) and (is_nil(secs) or secs >= 1) do
    Updater.counter(name, delta, secs)
  end

  @doc """
  Clears a counter with the given name.
  """
  def clear_counter(metric_name) when is_bitstring(metric_name) do
    clear_counter(name_to_exometer(:counters, metric_name))
  end

  def clear_counter(metric_name) when is_list(metric_name)  do
    :exometer.reset(metric_name)
  end

  @doc """
  Updates a gauge metric. If the metric doesn't exist, the metric is created
  and the metric is subscribed to the default reporter.
  """
  def update_gauge(name, value) when is_bitstring(name) do
    Updater.gauge(name, value)
  end

  @doc """
  Updates a timer metric. If the metric doesn't exist, it will be created and
  subscribed to the default reporter.

  The time units default to *microseconds*, but you can pass in a unit of
  :millis and the value will be converted.
  """
  defmacro timed(name, units \\ :micros, do: block) do
    converted_name = Elixometer.Utils.name_to_exometer(:timers, name)

    quote do
      {elapsed_us, rv} = :timer.tc(fn -> unquote(block) end)
      Updater.timer(unquote(converted_name), unquote(units), elapsed_us)
      rv
    end
  end

  def add_counter(metric_name, ttl_millis) do
    GenServer.cast(__MODULE__, {:add_counter, metric_name, ttl_millis})
  end

  def add_counter(metric_name) do
    GenServer.cast(__MODULE__, {:add_counter, metric_name, nil})
  end

  def metric_defined?(name) when is_bitstring(name) do
    name |> to_atom_list |> metric_defined?
  end

  def metric_defined?(name) do
    :ets.member(@elixometer_table, {:definitions, name})
  end

  def metric_subscribed?(name) do
    :ets.member(@elixometer_table, {:subscriptions, name})
  end

  def ensure_subscribed(name) do
    if not metric_subscribed?(name) do
      GenServer.call(__MODULE__, {:subscribe, name})
    end
  end

  def ensure_metric_defined(name, defn_fn) do
    if not metric_defined?(name) do
      GenServer.call(__MODULE__, {:define_metric, name, defn_fn})
    end

    :ok
  end

  @doc """
  Ensures a metric is correctly registered in Elixometer.
  This means that Elixometer knows about it and its metrics are
  subscribed to an exometer reporter
  """
  def ensure_registered(metric_name, register_fn) do
    try do
      ensure_metric_defined(metric_name, register_fn)
      subscribe(metric_name)
    rescue
      e in ErlangError -> e
    end
  end

  @doc """
  Ensures that a metric is subscribed to an exometer reporter.
  """
  def subscribe(metric_name) do
    if not metric_subscribed?(metric_name) do
      GenServer.call(__MODULE__, {:subscribe, metric_name})
    end
  end

  def handle_call({:subscribe, metric_name}, _caller, state) do
    create_subscription(metric_name)
    {:reply, :ok, state}
  end

  def handle_call({:define_metric, metric_name, defn_fn}, _caller, state) do
    # we re-check whether the metric is defined here to prevent
    # a race condition in ensure_metric_defined
    if not metric_defined?(metric_name) do
      defn_fn.()
      :ets.insert(@elixometer_table, {{:definitions, metric_name}, true})
    end

    {:reply, :ok, state}
  end

  def handle_cast({:add_counter, metric_name, ttl_millis}, config) do
    new_counters = Map.put(config.counters, metric_name, ttl_millis)
    {:noreply, %Config{config | counters: new_counters}}
  end

  def handle_info(:tick, config) do
    Enum.map(config.counters,
      fn({name, millis}) ->
        {:ok, [ms_since_reset: since_reset]} = :exometer.get_value(name, :ms_since_reset)
        if millis && since_reset >= millis do
          :exometer.reset(name)
        end
      end)

    {:noreply, config}
  end

  defp create_subscription(metric_name) do
    # If a metric isn't subscribed to our reporters, create a subscription in our
    # ets table and subscribe our metric to exometer's reporters.
    if not metric_subscribed?(metric_name) do
      cfg = Application.get_all_env(:elixometer)
      reporter = cfg[:reporter]
      interval = cfg[:update_frequency]
      subscribe_options = cfg[:subscribe_options] || []

      if reporter do
        :exometer.info(metric_name, :datapoints)
        |> Enum.map(&(:exometer_report.subscribe(reporter, metric_name, &1, interval, subscribe_options)))
      end
      :ets.insert(@elixometer_table, {{:subscriptions, metric_name}, true})
    end
  end

end
