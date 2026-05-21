defmodule Beamq.Scheduler do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    case Beamq.Store.get() do
      :empty ->
        :ok

      job ->
        spawn(fn ->
          Beamq.Worker.run(job)
        end)
    end

    tick()
    {:noreply, state}
  end

  defp tick do
    Process.send_after(self(), :tick, 1000)
  end
end
