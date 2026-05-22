defmodule Beamq.Scheduler do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    tick()
    # State now tracks running PIDs to Job IDs
    {:ok, %{running_tasks: %{}}}
  end

  def handle_info(:tick, state) do
    # Pull jobs continuously until the queue is empty
    new_state = dispatch_jobs(state)
    tick()
    {:noreply, new_state}
  end

  # --- Monitor Callbacks ---

  # 1. The worker finished successfully
  def handle_info({ref, result}, state) do
    # The task sends a message with its ref when it finishes
    Process.demonitor(ref, [:flush])
    {job_id, new_running_tasks} = Map.pop(state.running_tasks, ref)

    Beamq.Store.mark_completed(job_id)
    Logger.info("Job #{job_id} completed with result: #{inspect(result)}")

    {:noreply, %{state | running_tasks: new_running_tasks}}
  end

  # 2. The worker crashed or failed
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    {job_id, new_running_tasks} = Map.pop(state.running_tasks, ref)

    # We didn't lose the job! We know exactly which one failed.
    Beamq.Store.mark_failed(job_id)
    Logger.error("Job #{job_id} crashed! Reason: #{inspect(reason)}")

    {:noreply, %{state | running_tasks: new_running_tasks}}
  end

  # --- Internal Private Functions ---

  defp dispatch_jobs(state) do
    case Beamq.Store.get() do
      :empty ->
        state

      job ->
        # Spawn under the supervisor, but monitor it from the scheduler
        task = Task.Supervisor.async_nolink(Beamq.WorkerSupervisor, fn ->
          Beamq.Worker.run(job.payload)
        end)

        # Store the task reference so we know which job it belongs to
        new_running_tasks = Map.put(state.running_tasks, task.ref, job.id)

        # Immediately try to dispatch another job (Fixes the bottleneck)
        dispatch_jobs(%{state | running_tasks: new_running_tasks})
    end
  end

  defp tick do
    # Still ticks every second, but now it drains the queue instantly when it wakes
    Process.send_after(self(), :tick, 1000)
  end
end
