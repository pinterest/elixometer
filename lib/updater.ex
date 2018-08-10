defmodule Elixometer.Updater do
  @moduledoc false

  @max_messages 1000
  @default_formatter Elixometer.Utils

  import Elixometer, only: [ensure_registered: 2, add_counter: 2, add_counter: 1]
  use GenServer

  def init([]) do
    config = Application.get_env(:elixometer, __MODULE__, [])
    max_messages = Keyword.get(config, :max_messages, @max_messages)
    formatter = Keyword.get(config, :formatter, @default_formatter)
    {:ok, pobox} = :pobox.start_link(self(), max_messages, :queue)
    Process.register(pobox, :elixometer_pobox)
    activate_pobox()
    {:ok, %{formatter: formatter}}
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def timer(name, units, elapsed) do
    :pobox.post(:elixometer_pobox, {:timer, name, units, elapsed})
  end

  def gauge(name, value) do
    :pobox.post(:elixometer_pobox, {:gauge, name, value})
  end

  def counter(name, delta, reset_seconds) do
    :pobox.post(:elixometer_pobox, {:counter, name, delta, reset_seconds})
  end

  def spiral(name, delta, opts) do
    :pobox.post(:elixometer_pobox, {:spiral, name, delta, opts})
  end

  def histogram(name, delta, reset_seconds, truncate) do
    :pobox.post(:elixometer_pobox, {:histogram, name, delta, reset_seconds, truncate})
  end

  def handle_info({:mail, _pid, messages, _, _}, %{formatter: formatter} = state) do
    Enum.each(messages, fn message ->
      do_update(message, formatter)
    end)

    activate_pobox()

    {:noreply, state}
  end

  def do_update({:histogram, name, delta, aggregate_seconds, truncate}, formatter) do
    monitor = do_format(formatter, :histograms, name)

    ensure_registered(monitor, fn ->
      :exometer.new(
        monitor,
        :histogram,
        time_span: :timer.seconds(aggregate_seconds),
        truncate: truncate
      )
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:spiral, name, delta, opts}, formatter) do
    monitor = do_format(formatter, :spirals, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :spiral, opts)
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:counter, name, delta, reset_seconds}, formatter) do
    monitor = do_format(formatter, :counters, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :counter, [])

      if is_nil(reset_seconds) do
        add_counter(monitor)
      else
        add_counter(monitor, reset_seconds * 1000)
      end
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:gauge, name, value}, formatter) do
    monitor = do_format(formatter, :gauges, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :gauge, [])
    end)

    :exometer.update(monitor, value)
  end

  def do_update({:timer, name, units, elapsed_us}, formatter) do
    timer = do_format(formatter, :timers, name)

    ensure_registered(timer, fn ->
      :exometer.new(timer, :histogram, [])
    end)

    elapsed_time =
      cond do
        units in [:nanosecond, :nanoseconds] -> elapsed_us * 1000
        units in [:micros, :microsecond, :microseconds] -> elapsed_us
        units in [:millis, :millisecond, :milliseconds] -> div(elapsed_us, 1000)
        units in [:second, :seconds] -> div(elapsed_us, 1_000_000)
      end

    :exometer.update(timer, elapsed_time)
  end

  defp activate_pobox do
    :pobox.active(:elixometer_pobox, fn msg, _ -> {{:ok, msg}, :nostate} end, :nostate)
  end

  defp do_format(formatter, metric, name) when is_function(formatter) do
    formatter.(metric, name)
  end

  defp do_format(formatter, metric, name) do
    formatter.format(metric, name)
  end
end
