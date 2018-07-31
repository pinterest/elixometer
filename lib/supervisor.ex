defmodule Elixometer.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [worker(Elixometer, []), worker(Elixometer.Updater, [])]
    supervise(children, strategy: :one_for_one)
  end
end
