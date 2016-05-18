defmodule Elixometer.Utils do
  def name_to_exometer(metric_type, name) when is_bitstring(name) do
    config = Application.get_all_env(:elixometer)
    prefix = config[:metric_prefix] || "elixometer"
    base_name = case config[:env] do
                  nil -> "#{prefix}.#{metric_type}.#{name}"
                  :prod -> "#{prefix}.#{metric_type}.#{name}"
                  env -> "#{prefix}.#{env}.#{metric_type}.#{name}"
                end

    to_atom_list(base_name)
  end

  def to_atom_list(s) when is_bitstring(s) do
    s
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
  end

end
