defmodule Elixometer.Utils do
  @moduledoc false

  # Name may already have been converted elsewhere.
  def name_to_exometer(_metric_type, name) when is_list(name) do
    name
  end

  def name_to_exometer(metric_type, name) when is_bitstring(name) do
    config = Application.get_all_env(:elixometer)
    prefix = config[:metric_prefix] || "elixometer"

    base_name =
      case env(config[:env]) do
        nil -> "#{prefix}.#{metric_type}.#{name}"
        :prod -> "#{prefix}.#{metric_type}.#{name}"
        env -> "#{prefix}.#{env}.#{metric_type}.#{name}"
      end

    String.split(base_name, ".")
  end

  defp env({:system, var}) do
    case System.get_env(var) do
      nil -> nil
      v -> String.to_atom(v)
    end
  end

  defp env(val), do: val
end
