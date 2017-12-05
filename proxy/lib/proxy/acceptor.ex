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
  @spec start_link(non_neg_integer, String.t, service) :: {:ok, pid} | {:error, any}
  def start_link(port, service_name, service) do
    Task.start_link(__MODULE__, :run, [port, service_name, service])
  end

  @doc """
  Task's main function
  """
  @spec run(non_neg_integer, String.t, service) :: any
  def run(port, service_name, service) do
    {:ok, socket} = TCPSocket.listen(port)

    Logger.info fn ->
      "Accepting connections on port #{port} for service #{service_name}"
    end

    loop_acceptor(socket, service_name, service)
  end

  # Accepts connections with tail recursion
  @spec loop_acceptor(:gen_tcp.socket, String.t, service) :: any
  defp loop_acceptor(socket, service_name, service) do
    {:ok, client} = TCPSocket.accept(socket)

    Logger.debug fn ->
      "Accepted connection for service #{service_name}"
    end

    case ConnectionPool.create_connection(ConnectionPool, client,
                                          service_name, service) do
      {:ok, pid} ->
        :ok = TCPSocket.controlling_process(client, pid)
      {:error, error} ->
        TCPSocket.close(client)
        Logger.debug fn ->
          "Failed to create connection in ConnectionPool for service " <>
          "#{service_name}: #{inspect(error)}"
        end
    end

    loop_acceptor(socket, service_name, service)
  end
end
