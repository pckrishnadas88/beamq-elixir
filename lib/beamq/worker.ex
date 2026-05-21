defmodule Beamq.Worker do
  def run(job) do
    IO.inspect(job, label: "Executing job")

    :timer.sleep(1000)

    IO.puts("done")
  end
end
