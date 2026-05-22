defmodule Beamq.Worker do

  # 1. This clause catches the exact string "crash" and blows up
  def run("crash") do
    IO.puts("🧨 Worker is about to crash violently!")
    raise "Boom! Network timeout or bad data."
  end
  def run(job) do
    IO.inspect(job, label: "Executing job")

    :timer.sleep(1000)

    IO.puts("done")
  end
end
