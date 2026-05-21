defmodule Beamq.Application do
  use Application

  def start(_type, _args) do
    Beamq.Supervisor.start_link()
  end
end
