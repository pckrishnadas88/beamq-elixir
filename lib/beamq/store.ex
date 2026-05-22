defmodule Beamq.Store do
  use GenServer

  @table :beamq_jobs

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add(job) do
    GenServer.call(__MODULE__, {:add, job})
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def init(_) do
    :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{}}
  end

  def mark_completed(id) do
    GenServer.call(__MODULE__, {:update_status, id, :completed})
  end

  def mark_failed(id) do
    GenServer.call(__MODULE__, {:update_status, id, :failed})
  end

  def handle_call({:add, job}, _from, state) do
    id = :erlang.unique_integer([:monotonic])
    job_record = %{id: id, payload: job, status: :ready, attempts: 0}
    :ets.insert(@table, {id, job_record})
    {:reply, :ok, state}
  end

  def handle_call(:get, _from, state) do
    # Find the first :ready job using an ETS match specification
    match_spec = [{{:"$1", %{status: :ready}}, [], [:"$_"]}]
    case :ets.select(@table, match_spec, 1) do
      {[{id, job_record}], _continuation} ->
        # Transition state to running instead of deleting
        running_job = %{job_record | status: :running, attempts: job_record.attempts + 1}
        :ets.insert(@table, {id, running_job})
        {:reply, running_job, state}

      :"$end_of_table" ->
        {:reply, :empty, state}
    end
  end

  def handle_call({:update_status, id, new_status}, _from, state) do
    case :ets.lookup(@table, id) do
      [{^id, job_record}] ->
        :ets.insert(@table, {id, %{job_record | status: new_status}})
        {:reply, :ok, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end
end
