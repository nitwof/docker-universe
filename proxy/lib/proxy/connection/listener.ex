defmodule Proxy.Connection.Listener do
  @moduledoc """
  Task for listenning tcp socket.
  Sends all received messages to Kafka.
  Behaves like proxy between tcp socket and Kafka.
  """
  use Task

  require Logger

  alias Proxy.TCPSocket

  @type t :: Task.t

  @doc """
  Starts listener
  """
  @spec start_link(:gen_tcp.socket, String.t, non_neg_integer) :: {:ok, pid} | {:error, any}
  def start_link(socket, topic, partiton) do
    Task.start_link(__MODULE__, :run, [socket, topic, partiton])
  end

  @doc """
  Task's main function
  """
  @spec run(:gen_tcp.socket, String.t, non_neg_integer) :: any
  def run(socket, topic, partition) do
    case TCPSocket.read(socket) do
      {:ok, msg} ->

        Logger.debug fn ->
          "Received message #{inspect(msg)} from tcp socket"
        end
        Logger.debug fn ->
          "Sending message #{inspect(msg)} to Kafka #{topic}:#{partition}"
        end

        KafkaEx.produce(topic, partition, msg)
        run(socket, topic, partition)
      {:error, _} ->
        Logger.debug("TCP Connection closed")
        exit(:normal)
    end
  end

  @doc """
  Stops listener
  """
  @spec stop(t) :: true
  def stop(pid) do
    Process.exit(pid, :normal)
  end
end
