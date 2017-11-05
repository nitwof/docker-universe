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

  @type t :: GenServer.server

  @sleep_timeout 100

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
  Stops connection
  """
  @spec stop(t) :: :ok
  def stop(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Stops connection.
  But waiting when handles all messages from queue before this
  """
  @spec soft_stop(t) :: :ok
  def soft_stop(pid) do
    GenServer.cast(pid, :soft_stop)
  end

  # Server

  def init({socket, group_name, topic, partition_from, partition_to}) do
    Process.flag(:trap_exit, true)

    with {:ok, listener} <- Listener.start_link(socket, topic, partition_to),
         {:ok, consumer} <- Consumer.start_link(socket, group_name, topic, partition_from)
    do
      state = %{
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

  def handle_info({:EXIT, _from, _reason}, _state) do
    exit(:normal)
  end

  def handle_cast(:soft_stop, %{consumer: consumer}) do
    wait_empty_queue(consumer)
    exit(:normal)
  end

  @spec wait_empty_queue(pid) :: :ok
  defp wait_empty_queue(consumer) do
    if Consumer.queue_empty?(consumer) do
      :ok
    else
      Process.sleep(@sleep_timeout)
      wait_empty_queue(consumer)
    end
  end
end
