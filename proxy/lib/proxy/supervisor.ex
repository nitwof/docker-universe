defmodule Proxy.Supervisor do
  use Supervisor

  alias Proxy.TCPServer
  alias Proxy.Producer.TCPMessagesHandler

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    event_handlers = [[TCPMessagesHandler, []]]
    children = [
      {TCPServer.Supervisor, [event_handlers]}
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Proxy.Supervisor)
  end
end
