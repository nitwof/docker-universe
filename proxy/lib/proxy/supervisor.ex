defmodule Proxy.Supervisor do
  use Supervisor

  alias Proxy.ConnectionPool
  alias Proxy.Acceptor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {ConnectionPool, name: ConnectionPool},
      Supervisor.child_spec(Acceptor,
        start: {Acceptor, :start_link, [8080, ConnectionPool]},
        restart: :permanent
      )
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Proxy.Supervisor)
  end
end
