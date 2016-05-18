defmodule Elixometer.Updater do
  @moduledoc """
  A capped worker that updates metrics.
  """

  @max_messages 1000

  import Elixometer, only: [ensure_registered: 2, add_counter: 2, add_counter: 1]
  import Elixometer.Utils
  use GenServer

  def init([]) do
    {:ok, pobox} = :pobox.start_link(self, @max_messages, :queue)
    Process.register(pobox, :elixometer_pobox)
    activate_pobox
    {:ok, nil}
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def timer(name, units, elapsed) when is_bitstring(name) do
    elixometer_name = name_to_exometer(:timers, name)
    timer(elixometer_name, units, elapsed)
  end

  def timer(name, units, elapsed) when is_list(name) do
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

  def histogram(name, delta, reset_seconds) do
    :pobox.post(:elixometer_pobox, {:histogram, name, delta, reset_seconds})
  end

  def handle_info({:mail, _pid, messages, _, _}, state) do
    messages
    |> Enum.each(&do_update/1)

    activate_pobox

    {:noreply, state}
  end

  def do_update({:histogram, name, delta, aggregate_seconds}) do
    monitor = name_to_exometer(:histograms, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :histogram, [time_span: :timer.seconds(aggregate_seconds)])
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:spiral, name, delta, opts}) do
    monitor = name_to_exometer(:spirals, name)
    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :spiral,  opts)
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:counter, name, delta, reset_seconds}) do
    monitor = name_to_exometer(:counters, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :counter, [])

      if is_nil reset_seconds do
        add_counter(monitor)
      else
        add_counter(monitor, reset_seconds * 1000)
      end
    end)

    :exometer.update(monitor, delta)
  end

  def do_update({:gauge, name, value}) do
    monitor = name_to_exometer(:gauges, name)

    ensure_registered(monitor, fn ->
      :exometer.new(monitor, :gauge, [])
    end)

    :exometer.update(monitor, value)
  end

  def do_update({:timer, name, units, elapsed_us}) do
    ensure_registered(name, fn ->
      :exometer.new(name, :histogram, [])
    end)

    elapsed_time = case units do
                     :micros -> elapsed_us
                     :millis -> elapsed_us / 1000
                   end

    :exometer.update(name, elapsed_time)
  end

  defp activate_pobox do
    :pobox.active(:elixometer_pobox, fn(msg, _) -> {{:ok, msg}, :nostate} end, :nostate)
  end
end
