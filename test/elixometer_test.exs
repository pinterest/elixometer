defmodule ElixometerTest do
  use ExUnit.Case

  use Elixometer
  alias Elixometer.TestReporter, as: Reporter

  defmodule DeclarativeTest do
    use Elixometer

    @timed key: "declarative_test.my_timed_method"
    def my_timed_method(a, b, c, d) do
      a + b + c + d
    end

    def arity_test(a) do
      a + 1
    end

    @timed key: "arity_test"
    def arity_test(a, b) do
      a + b
    end

    @timed key: "declarative_test.my_other_timed"
    def my_other_timed_method(_a) do
      3
    end

    @timed key: "my_test.guarded"
    def my_other_timed_method2(a) when is_list(a) do
    end

    @doc "Testing doc"
    @timed key: "timed_with_doc"
    def timed_with_doc do
      10
    end

    def public_secret_timed do
      secret_timed()
    end

    @timed key: "defp_timed"
    defp secret_timed do
      100
    end

    @timed key: :auto
    def auto_named do
    end

    @timed key: "returning_nil"
    def timed_returning_nil(), do: nil

    @timed key: "returning_ast"
    def timed_returning_ast(), do: [do: :value]

    @timed key: "sleep", units: :millisecond
    def timed_sleep(duration), do: :timer.sleep(duration)
  end

  setup do
    original_env = Application.get_env(:elixometer, :env)
    on_exit(fn -> Application.put_env(:elixometer, :env, original_env) end)

    :ok
  end

  defp wait_for_messages do
    :timer.sleep(50)
  end

  defp metric_exists?(metric_name) when is_bitstring(metric_name) do
    metric_name |> String.split(".") |> metric_exists?
  end

  defp metric_exists?(metric_name) when is_list(metric_name) do
    wait_for_messages()
    metric_name in Reporter.metric_names()
  end

  defp subscription_exists?(metric_name) when is_bitstring(metric_name) do
    metric_name |> String.split(".") |> subscription_exists?
  end

  defp subscription_exists?(metric_name) when is_list(metric_name) do
    wait_for_messages()
    metric_name in Reporter.subscription_names()
  end

  defp subscription_exists?(metric_name, datapoint) when is_bitstring(metric_name) do
    metric_name |> String.split(".") |> subscription_exists?(datapoint)
  end

  defp subscription_exists?(metric_name, datapoint) when is_list(metric_name) do
    wait_for_messages()
    {metric_name, datapoint} in Reporter.subscriptions()
  end

  test "a gauge registers its name" do
    update_gauge("register", 10)

    assert metric_exists?("elixometer.test.gauges.register")
  end

  test "a gauge automatically subscribes" do
    update_gauge("subscription", 10)

    assert subscription_exists?("elixometer.test.gauges.subscription")
  end

  test "a histogram registers its name" do
    update_histogram("register", 10)

    assert metric_exists?("elixometer.test.histograms.register")
  end

  test "a histogram automatically subscribes" do
    update_histogram("subscription", 1)

    assert subscription_exists?("elixometer.test.histograms.subscription")
  end

  test "a histogram does not truncate percentiles" do
    update_histogram("sensor_reading", 1.13, 1, false)
    :timer.sleep(1000)
    {:ok, not_trunc} = get_metric_value("elixometer.test.histograms.sensor_reading", :"99")
    assert not_trunc == 0.0
  end

  test "a histogram does truncate percentiles" do
    update_histogram("sensor_reading_truncated", 1.13, 1)
    :timer.sleep(1000)
    {:ok, trunc} = get_metric_value("elixometer.test.histograms.sensor_reading_truncated", :"99")
    assert trunc == 0
  end

  test "a counter registers its name" do
    update_counter("register", 1)

    assert metric_exists?("elixometer.test.counters.register")
  end

  test "a counter automatically subscribes" do
    update_counter("subscription", 1)

    assert subscription_exists?("elixometer.test.counters.subscription")
  end

  test "clearing a counter sets it to 0" do
    update_counter("to_be_cleared", 1)
    name = ["elixometer", "test", "counters", "to_be_cleared"]

    wait_for_messages()
    assert {:ok, [value: 1]} == :exometer.get_value(name, :value)

    clear_counter("to_be_cleared")
    assert {:ok, [value: 0]} == :exometer.get_value(name, :value)

    assert metric_exists?("elixometer.test.counters.to_be_cleared")
  end

  test "a counter resets itself after its time has elapsed" do
    update_counter("reset", 1, reset_seconds: 1)

    wait_for_messages()

    expected_name = ["elixometer", "test", "counters", "reset"]
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

    wait_for_messages()

    expected_name = ["elixometer", "test", "counters", "no_reset"]
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

    assert metric_exists?("elixometer.test.timers.register")
  end

  test "a timer automatically subscribes" do
    timed("subscription", do: 1 + 1)

    assert subscription_exists?("elixometer.test.timers.subscription")
  end

  test "a timer can time in seconds" do
    timed("second", :second, do: :timer.sleep(1))

    assert subscription_exists?("elixometer.test.timers.second")
    [{99, s}] = Reporter.value_for("elixometer.test.timers.second", 99)
    assert s <= 1
  end

  test "a timer can time in milliseconds" do
    timed("millisecond", :millisecond, do: :timer.sleep(1))

    assert subscription_exists?("elixometer.test.timers.millisecond")
    [{99, ms}] = Reporter.value_for("elixometer.test.timers.millisecond", 99)
    assert ms <= 10
  end

  test "a timer times in microseconds by default" do
    timed("microsecond", do: :timer.sleep(1))

    assert subscription_exists?("elixometer.test.timers.microsecond")
    [{_data_point, value}] = Reporter.value_for("elixometer.test.timers.microsecond", 99)
    assert value > 1000
  end

  test "a timer can time in nanoseconds" do
    timed("nanosecond", :nanosecond, do: :timer.sleep(1))

    assert subscription_exists?("elixometer.test.timers.nanosecond")
    [{99, ns}] = Reporter.value_for("elixometer.test.timers.nanosecond", 99)
    assert ns > 1_000_000
  end

  @tag elixir: 1.5
  test "a bodyless timer defined in a module raises a RuntimeError" do
    on_exit(fn ->
      :code.delete(BodylessModule)
      :code.purge(BodylessModule)
    end)

    assert_raise RuntimeError, "timed function must have a body", fn ->
      defmodule BodylessModule do
        use Elixometer
        @timed key: :auto
        def bodyless
      end
    end
  end

  test "a timer defined with attributes measures time" do
    DeclarativeTest.timed_sleep(100)
    assert subscription_exists?("elixometer.test.timers.sleep")
    [{99, ns}] = Reporter.value_for("elixometer.test.timers.sleep", 99)
    assert ns in 100..1_000
  end

  test "a timer defined in the module's declaration" do
    assert DeclarativeTest.my_timed_method(1, 2, 3, 4) == 10
    assert metric_exists?("elixometer.test.timers.declarative_test.my_timed_method")
  end

  test "a timer defined in the module's definition is specific to an arity" do
    DeclarativeTest.arity_test(1)

    refute metric_exists?("elixometer.test.timers.arity_test")

    DeclarativeTest.arity_test(1, 2)
    assert metric_exists?("elixometer.test.timers.arity_test")
  end

  test "a timer defined with attributes and docs" do
    DeclarativeTest.timed_with_doc()

    assert metric_exists?("elixometer.test.timers.timed_with_doc")
  end

  test "a timer defined with attributes works with defp" do
    DeclarativeTest.public_secret_timed()

    assert metric_exists?("elixometer.test.timers.defp_timed")
  end

  test "a timer defined with no key auto generates one" do
    DeclarativeTest.auto_named()

    assert metric_exists?("elixometer.test.timers.elixometer_test.declarative_test.auto_named")
  end

  test "a timer defined in a module can return nil" do
    assert DeclarativeTest.timed_returning_nil() == nil
    assert metric_exists?("elixometer.test.timers.returning_nil")
  end

  test "a timer defined in a module can return an AST body" do
    assert DeclarativeTest.timed_returning_ast() == [do: :value]
    assert metric_exists?("elixometer.test.timers.returning_ast")
  end

  test "a spiral registers its name" do
    update_spiral("register", 1)

    assert metric_exists?("elixometer.test.spirals.register")
  end

  test "a spiral subscribes" do
    update_spiral("subscription", 1)

    assert subscription_exists?("elixometer.test.spirals.subscription")
  end

  test "name can be precomputed" do
    name = Elixometer.Utils.format(:spirals, "precomputed_counter")
    update_spiral(name, 123)
    wait_for_messages()

    assert get_metric_value("elixometer.test.spirals.precomputed_counter", :one) == {:ok, 123}
  end

  test "name can be precomputed with env config from environmental variable" do
    System.put_env("ELIXOMETER_ENV", "staging")
    Application.put_env(:elixometer, :env, {:system, "ELIXOMETER_ENV"})

    name = Elixometer.Utils.format(:spirals, "precomputed_counter")
    update_spiral(name, 123)
    wait_for_messages()

    assert get_metric_value("elixometer.staging.spirals.precomputed_counter", :one) == {:ok, 123}
  end

  test ~s(name can be precomputed with env config from environmental variable and env is "prod") do
    System.put_env("ELIXOMETER_ENV", "prod")
    Application.put_env(:elixometer, :env, {:system, "ELIXOMETER_ENV"})

    name = Elixometer.Utils.format(:spirals, "precomputed_counter")
    update_spiral(name, 123)
    wait_for_messages()

    assert get_metric_value("elixometer.spirals.precomputed_counter", :one) == {:ok, 123}
  end

  test "name can be precomputed with env config from environmental variable and env is not set" do
    Application.put_env(:elixometer, :env, {:system, "ELIXOMETER_MISSING_ENV"})

    name = Elixometer.Utils.format(:spirals, "precomputed_counter_env_not_set")
    update_spiral(name, 123)
    wait_for_messages()

    assert get_metric_value("elixometer.spirals.precomputed_counter_env_not_set", :one) ==
             {:ok, 123}
  end

  test "getting a value with no arguments" do
    update_gauge("value", 100)

    assert :exometer.get_value([:elixometer, :test, :gauges, :value]) ==
             get_metric_value("elixometer.test.gauges.value")
  end

  test "getting a value with no arguments for a wildcard key" do
    update_gauge("user1", 100)
    update_gauge("user2", 15)

    wait_for_messages()

    assert :exometer.get_values(["elixometer", "test", "gauges", :_]) ==
             get_metric_values("elixometer.test.gauges._")
  end

  test "getting a specific metric" do
    update_gauge("value_2", 23)

    wait_for_messages()

    assert {:ok, 23} == get_metric_value("elixometer.test.gauges.value_2", :value)
  end

  test "getting a specific metric for a wildcard key" do
    update_gauge("users.registered", 100)
    update_gauge("users.anonymous", 15)

    wait_for_messages()

    assert {:ok, 115} == get_metric_values("elixometer.test.gauges.users._", :value)
  end

  test "getting a value for a metric that doesn't exist" do
    assert {:error, :not_found} == get_metric_value("elixometer.test.gauges.blah")
  end

  test "getting a datapoint that doesn't exist" do
    update_gauge("no_datapoint", 22)

    wait_for_messages()

    assert {:ok, :undefined} ==
             get_metric_value("elixometer.test.gauges.no_datapoint", :bad_datapoint)
  end

  test "blacklisting subscriptions works" do
    # Remove :median from the subscriptions
    Application.put_env(:elixometer, :excluded_datapoints, [:median])
    update_histogram("uniquelittlefoobar", 42)
    key = ["elixometer", "test", "histograms", "uniquelittlefoobar"]

    refute subscription_exists?(key, :median)
  end

  test "getting a datapoint from a metric that doesn't exist" do
    assert {:error, :not_found} == get_metric_value("elixometer.test.bad.bad")
  end

  test "a subscription that has additional subscription options" do
    Application.put_env(:elixometer, :subscribe_options, some_option: 42)

    update_counter("subscribe_options", 1)

    assert subscription_exists?("elixometer.test.counters.subscribe_options")
    assert [some_option: 42] = Reporter.options_for("elixometer.test.counters.subscribe_options")
  end

  test "metrics created elsewhere can be retrieved" do
    foreign_metric = [:created, :somewhere]
    :exometer.new(foreign_metric, :spiral, [])
    :exometer.update(foreign_metric, 100)

    assert {:ok, data} = get_metric_value([:created, :somewhere])
    assert data[:one] == 100
  end
end
