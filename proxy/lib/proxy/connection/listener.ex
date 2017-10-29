defmodule Proxy.Connection.Listener do
  use Task

  require Logger

  alias Proxy.TCPSocket

  def start_link(socket, topic, partiton) do
    Task.start_link(__MODULE__, :run, [socket, topic, partiton])
  end

  def run(socket, topic, partition) do
    case TCPSocket.read(socket) do
      {:ok, msg} ->
        Logger.debug("Received message '#{inspect(msg)}' from tcp socket")
        Logger.debug("Sending message '#{inspect(msg)}' to Kafka #{topic}:#{partition}}")
        KafkaEx.produce(topic, partition, msg)
        run(socket, topic, partition)
      {:error, _} ->
        exit(:shutdown)
    end
  end
end
