defmodule Proxy.Acceptor do
  use Task

  require Logger

  alias Proxy.TCPSocket
  alias Proxy.ConnectionPool

  def start_link(port, connection_pool) do
    Task.start_link(__MODULE__, :run, [port, connection_pool])
  end

  def run(port, connection_pool) do
    {:ok, socket} = TCPSocket.listen(port)
    Logger.info("Accepting connections on port #{port}")

    loop_acceptor(socket, connection_pool)
  end

  defp loop_acceptor(socket, connection_pool) do
    {:ok, client} = TCPSocket.accept(socket)

    Logger.debug("Accepted connection")
    with {:ok, pid} <- ConnectionPool.create_connection(connection_pool, client)
    do
      :ok = TCPSocket.controlling_process(client, pid)
    else
      _ ->
        Logger.debug("Failed to create connection in ConnectionPool")
        TCPSocket.close(client)
    end

    loop_acceptor(socket, connection_pool)
  end
end
