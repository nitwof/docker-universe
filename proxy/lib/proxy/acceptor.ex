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
  @spec start_link(String.t, non_neg_integer, service) :: {:ok, pid} | {:error, any}
  def start_link(_service_name, port, service) do
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

    Logger.debug "Accepted connection"

    case ConnectionPool.create_connection(ConnectionPool, client, service) do
      {:ok, _} -> :ok
      {:error, _} ->
        TCPSocket.close(client)
        Logger.debug "Failed to create connection in ConnectionPool"
    end

    loop_acceptor(socket, service)
  end
end
