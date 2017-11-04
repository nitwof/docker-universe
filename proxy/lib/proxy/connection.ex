defmodule Proxy.Connection do
  @moduledoc """
  Storage for tcp socket.
  Provides functions manage tcp socket.
  Starts tcp socket listener and kafka consumer.
  Shutdowns on listener or consumer exit.
  """
  use GenServer

  require Logger

  alias Proxy.Connection.Listener
  alias Proxy.Connection.Consumer

  # Client

  @doc """
  Starts connection
  """
  @spec start_link(:gen_tcp.socket, String.t, String.t,
                   non_neg_integer, non_neg_integer) :: {:ok, pid} | {:error, any}
  def start_link(socket, group_name, topic, partition_from, partition_to) do
    GenServer.start_link(__MODULE__,
      {socket, group_name, topic, partition_from, partition_to}
    )
  end

  @doc """
  Sends message to tcp socket
  """
  @spec send_message(GenServer.server, String.t) :: :ok
  def send_message(pid, data) do
    GenServer.call(pid, {:send_message, data})
  end

  # Server

  def init({socket, group_name, topic, partition_from, partition_to}) do
    with {:ok, listener} <- Listener.start_link(socket, topic, partition_to),
         {:ok, consumer} <- Consumer.start_link(self(), group_name, topic, partition_from)
    do
      state = %{
        socket: socket,
        kafka_group_name: group_name,
        kafka_topic: topic,
        kafka_partition_from: partition_from,
        kafka_partition_to: partition_to,
        listener: listener,
        consumer: consumer
      }
      {:ok, state}
    else
      err -> {:error, err}
    end
  end

  def handle_call({:send_message, msg}, _from, %{socket: socket} = state) do
    Logger.debug fn ->
      "Sending message '#{inspect(msg)}' to tcp socket"
    end
    :gen_tcp.send(socket, msg)
    {:reply, :ok, state}
  end
end
