defmodule Elixometer.Formatter do
  @type metric_type :: :counter | :gauge | :histograms | :spirals | :timer
  @callback format(metric_type, String.t()) :: [String.t()]
end
