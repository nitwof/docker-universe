defmodule Proxy.TCPServer.Supervisor do
  use Supervisor

  alias Proxy.TCPServer
  alias Proxy.TCPServer.ConnectionPool
  alias Proxy.TCPServer.Acceptor

  def start_link([event_handlers]) do
    Supervisor.start_link(__MODULE__, event_handlers, name: TCPServer.Supervisor)
  end

  def init(event_handlers) do
    children = [
      {ConnectionPool, name: ConnectionPool},
      Supervisor.child_spec(
        {Acceptor, [8080, ConnectionPool, event_handlers]}, restart: :permanent
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
