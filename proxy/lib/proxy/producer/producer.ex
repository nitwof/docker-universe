defmodule Proxy.Producer do
  use Supervisor

  alias Proxy.Producer.Server

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Task.Supervisor, name: Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Server.accept(8080) end},
                            restart: :permanent)
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Producer.Supervisor)
  end
end
