defmodule Proxy.Acceptor do
  @moduledoc """
  Task that represents acception loop.
  """
  use Task

  require Logger

  alias Proxy.TCPSocket
  alias Proxy.ConnectionPool

  @type service :: {String.t, non_neg_integer}

  @doc """
  Starts task
  """
  @spec start_link(non_neg_integer, service) :: {:ok, pid} | {:error, any}
  def start_link(port, service) do
    Task.start_link(__MODULE__, :run, [port, service])
  end

  @doc """
  Task's main function
  """
  @spec run(non_neg_integer, service) :: any
  def run(port, service) do
    {:ok, socket} = TCPSocket.listen(port)

    Logger.info fn ->
      "Accepting connections on port #{port}"
    end

    loop_acceptor(socket, service)
  end

  # Accepts connections with tail recursion
  @spec loop_acceptor(:gen_tcp.socket, service) :: any
  defp loop_acceptor(socket, service) do
    {:ok, client} = TCPSocket.accept(socket)

    Logger.debug fn ->
      "Accepted connection"
    end

    case ConnectionPool.create_connection(ConnectionPool, client, service) do
      {:ok, pid} ->
        :ok = TCPSocket.controlling_process(client, pid)
      _ ->
        TCPSocket.close(client)
        Logger.debug fn ->
          "Failed to create connection in ConnectionPool"
        end
    end

    loop_acceptor(socket, service)
  end
end
