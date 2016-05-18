defmodule ElixometerTest do
  use ExUnit.Case

  use Elixometer
  alias Elixometer.TestReporter, as: Reporter

  defmodule DeclarativeTest do
    use Elixometer

    @timed(key: "declarative_test.my_timed_method")
    def my_timed_method(a, b, c, d) do
      a + b + c + d
    end

    def arity_test(a) do
      a + 1
    end

    @timed(key: "arity_test")
    def arity_test(a, b) do
      a + b
    end

    @timed(key: "declarative_test.my_other_timed")
    def my_other_timed_method(_a) do
      3
    end

    @timed(key: "my_test.guarded")
    def my_other_timed_method2(a) when is_list(a) do
    end

    @doc "Testing doc"
    @timed(key: "timed_with_doc")
    def timed_with_doc do
      10
    end

    def public_secret_timed do
      secret_timed
    end

    @timed(key: "defp_timed")
    defp secret_timed do
      100
    end

    @timed(key: :auto)
    def auto_named do

    end

  end

  setup do
    :ok
  end

  defp wait_for_messages do
    :timer.sleep 10
  end

  defp to_elixometer_name(metric_name) when is_bitstring(metric_name) do
    metric_name
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
  end

  def metric_exists(metric_name) when is_bitstring(metric_name) do
    metric_name |> to_elixometer_name |> metric_exists
  end

  def metric_exists(metric_name) when is_list(metric_name) do
    wait_for_messages
    metric_name in Reporter.metric_names
  end

  def subscription_exists(metric_name) when is_bitstring(metric_name) do
    metric_name |> to_elixometer_name |> subscription_exists
  end

  def subscription_exists(metric_name) when is_list(metric_name) do
    wait_for_messages
    metric_name in Reporter.subscriptions
  end

  test "a gauge registers its name" do
    update_gauge("register", 10)

    assert metric_exists "elixometer.test.gauges.register"
  end

  test "a gauge automatically subscribes" do
    update_gauge("subscription", 10)

    assert subscription_exists "elixometer.test.gauges.subscription"
  end

  test "a histogram registers its name" do
    update_histogram("register", 10)

    assert metric_exists "elixometer.test.histograms.register"
  end

  test "a histogram automatically subscribes" do
    update_histogram("subscription", 1)

    assert subscription_exists "elixometer.test.histograms.subscription"
  end

  test "a counter registers its name" do
    update_counter("register", 1)

    assert metric_exists "elixometer.test.counters.register"
  end

  test "a counter automatically subscribes" do
    update_counter("subscription", 1)

    assert subscription_exists "elixometer.test.counters.subscription"
  end

  test "a counter resets itself after its time has elapsed" do
    update_counter("reset", 1, reset_seconds: 1)

    wait_for_messages

    expected_name = [:elixometer, :test, :counters, :reset]
    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 1

    :timer.sleep(500)
    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 1

    :timer.sleep(800)

    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 0
  end

  test "a counter does not reset itself if reset_seconds is nil" do
    update_counter("no_reset", 1, reset_seconds: nil)

    wait_for_messages

    expected_name = [:elixometer, :test, :counters, :no_reset]
    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 1

    :timer.sleep(500)
    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 1

    :timer.sleep(800)

    {:ok, [value: val]} = :exometer.get_value(expected_name, :value)
    assert val == 1
  end

  test "a counter fails to register if reset_seconds is < 1" do
    assert_raise FunctionClauseError, fn -> update_counter("will_fail", 1, reset_seconds: 0) end
  end

  test "a timer registers its name" do
    timed("register", do: 1 + 1)

    assert metric_exists "elixometer.test.timers.register"
  end

  test "a timer automatically subscribes" do
    timed("subscription", do: 1 + 1)

    assert subscription_exists "elixometer.test.timers.subscription"
  end

  test "a timer can time in milliseconds" do
    timed("millis", :millis, do: :timer.sleep(1))

    assert subscription_exists "elixometer.test.timers.millis"
    [{99, ms}] = Reporter.value_for("elixometer.test.timers.millis", 99)
    assert ms <= 10
  end

  test "a timer times in microseconds by default" do
    timed("micros", do: :timer.sleep(1))

    assert subscription_exists "elixometer.test.timers.micros"
    [{_data_point, value}] = Reporter.value_for("elixometer.test.timers.micros", 99)
    assert value > 1000
  end

  test "a timer defined in the module's declaration" do
    rv = DeclarativeTest.my_timed_method(1, 2, 3, 4)

    assert rv == 1 + 2 + 3 + 4
    assert metric_exists "elixometer.test.timers.declarative_test.my_timed_method"
  end

  test "a timer defined in the module's definition is specific to an arity" do
    DeclarativeTest.arity_test(1)

    refute metric_exists "elixometer.test.timers.arity_test"

    DeclarativeTest.arity_test(1, 2)
    assert metric_exists "elixometer.test.timers.arity_test"
  end

  test "a timer defined with attributes and docs" do
    DeclarativeTest.timed_with_doc

    assert metric_exists "elixometer.test.timers.timed_with_doc"
  end

  test "a timer defined with attributes works with defp" do
    DeclarativeTest.public_secret_timed

    assert metric_exists "elixometer.test.timers.defp_timed"
  end

  test "a timer defined with no key auto generates one" do
    DeclarativeTest.auto_named

    assert metric_exists "elixometer.test.timers.elixometer_test.declarative_test.auto_named"
  end

  test "a spiral registers its name" do
    update_spiral("register", 1)

    assert metric_exists "elixometer.test.spirals.register"
  end

  test "a spiral subscribes" do
    update_spiral("subscription", 1)

    assert subscription_exists "elixometer.test.spirals.subscription"
  end

  test "getting a value with no arguments" do
    update_gauge "value", 100

    assert :exometer.get_value([:elixometer, :test, :gauges, :value]) == get_metric_value("elixometer.test.gauges.value")
  end

  test "getting a specific metric" do
    update_gauge "value_2", 23

    wait_for_messages

    assert {:ok, 23} == get_metric_value("elixometer.test.gauges.value_2", :value)
  end

  test "getting a value for a metric that doesn't exist" do
    assert {:error, :not_found} == get_metric_value("elixometer.test.gauges.blah")
  end

  test "getting a datapoint that doesn't exist" do
    update_gauge "no_datapoint", 22

    wait_for_messages

    assert {:ok, :undefined} == get_metric_value("elixometer.test.gauges.no_datapoint", :bad_datapoint)

  end

  test "getting a datapoint from a metric that doesn't exist" do
    assert {:error, :not_found} == get_metric_value("elixometer.test.bad.bad")
  end

end
