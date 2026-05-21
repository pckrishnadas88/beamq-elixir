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

  def handle_call({:add, job}, _from, state) do
    id = :erlang.unique_integer([:monotonic])
    :ets.insert(@table, {id, job})
    {:reply, :ok, state}
  end

  def handle_call(:get, _from, state) do
    case :ets.first(@table) do
      :"$end_of_table" ->
        {:reply, :empty, state}

      id ->
        [{^id, job}] = :ets.lookup(@table, id)
        :ets.delete(@table, id)
        {:reply, job, state}
    end
  end
end
