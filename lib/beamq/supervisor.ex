defmodule Beamq.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      Beamq.Store,
      Beamq.Scheduler
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
