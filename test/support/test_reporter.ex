defmodule Elixometer.TestReporter do
  @moduledoc false

  # exometer callbacks
  def exometer_init(_opts) do
    {:ok, nil}
  end

  def exometer_newentry(_entry, state) do
    {:ok, state}
  end

  def exometer_report(_metric, _datapoint, _extra, _value, state) do
    {:ok, state}
  end

  def exometer_subscribe(_name, _metric, _timeout, _opts, state) do
    {:ok, state}
  end

  def exometer_info(_cmd, state) do
    {:ok, state}
  end

  # end exometer callbacks

  def metric_names do
    {:ok, names} = :exometer_report.list_metrics()
    Enum.map(names, fn {name, _, _, _} -> name end)
  end

  def subscriptions do
    Application.get_env(:elixometer, :reporter)
    |> :exometer_report.list_subscriptions()
    |> Enum.map(fn {metric_name, datapoint, _, _} -> {metric_name, datapoint} end)
  end

  def subscription_names do
    Enum.map(subscriptions(), fn {name, _datapoint} -> name end)
  end

  def value_for(metric_name, datapoint) when is_bitstring(metric_name) do
    metric_name
    |> String.split(".")
    |> value_for(datapoint)
  end

  def value_for(metric_name, datapoint) do
    {:ok, value} = :exometer.get_value(metric_name, datapoint)
    value
  end

  def options_for(metric_name) when is_bitstring(metric_name) do
    metric_name
    |> String.split(".")
    |> options_for
  end

  def options_for(metric_name) do
    Application.get_env(:elixometer, :reporter)
    |> :exometer_report.list_subscriptions()
    |> Enum.find_value(fn
      {^metric_name, _, _, extra} -> extra
      _ -> nil
    end)
  end
end
