defmodule Elixometer.Formatter do
  @callback format(String.t(), String.t()) :: [String.t()]
end
