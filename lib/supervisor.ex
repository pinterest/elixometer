defmodule Elixometer.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    children = [Elixometer, Elixometer.Updater]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
