defmodule Proxy.Acceptor do
  @moduledoc """
  Task that represents acception loop.
  """
  use Task

  require Logger

  alias Proxy.TCPSocket
  alias Proxy.ConnectionPool

  @doc """
  Starts task
  """
  @spec start_link(non_neg_integer, pid) :: {:ok, pid} | {:error, any}
  def start_link(port, connection_pool) do
    Task.start_link(__MODULE__, :run, [port, connection_pool])
  end

  @doc """
  Task's main function
  """
  @spec run(non_neg_integer, pid) :: any
  def run(port, connection_pool) do
    {:ok, socket} = TCPSocket.listen(port)
    Logger.info("Accepting connections on port #{port}")

    loop_acceptor(socket, connection_pool)
  end

  @doc """
  Accepts connections with tail recursion
  """
  @spec loop_acceptor(:gen_tcp.socket, pid) :: any
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
