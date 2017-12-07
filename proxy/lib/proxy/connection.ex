defmodule Proxy.Connection do
  @moduledoc """
  Provides functions for managing connection
  """

  alias Proxy.Connection
  alias Proxy.Connection.Listener
  alias Proxy.Connection.Consumer
  alias Proxy.TCPSocket

  defstruct [
    :listener,
    :consumer,
    :socket,
    :group,
    :topic,
    :input_partition,
    :output_partition
  ]

  # @wait_timeout 10

  @type t :: %Connection{}

  @doc """
  Starts new connection
  """
  @spec start(:gen_tcp.socket, String.t, String.t, non_neg_integer, non_neg_integer) ::
        {:ok, t} | {:error, any}
  def start(socket, group, topic, input_partition, output_partition) do
    with {:ok, listener} <- Listener.start_link(socket, topic, input_partition),
         {:ok, consumer} <- Consumer.start_link(socket, group, topic, output_partition)
    do
      {:ok,
        %Connection{
          listener: listener,
          consumer: consumer,
          socket: socket,
          group: group,
          topic: topic,
          input_partition: input_partition,
          output_partition: output_partition
        }
      }
    end
  end

  @doc """
  Starts new connection from existsing Connection struct
  """
  @spec start(t) :: {:ok, t} | {:error, any}
  def start(%Connection{socket: socket, group: group, topic: topic,
                        input_partition: input_partition,
                        output_partition: output_partition}) do
   start(socket, group, topic, input_partition, output_partition)
  end

  @doc """
  Stops connection
  """
  @spec stop(t) :: :ok
  def stop(%Connection{listener: listener, consumer: consumer, socket: socket}) do
    Listener.stop(listener)
    Consumer.stop(consumer)
    TCPSocket.close(socket)
    :ok
  end

  @doc """
  Stops connection but waits for empty queue
  """
  @spec soft_stop(t) :: :ok
  def soft_stop(%Connection{listener: listener, consumer: consumer,
                            socket: socket}) do
    Listener.stop(listener)
    wait_for_empty_queue(consumer)
    Consumer.stop(consumer)
    TCPSocket.close(socket)
  end

  @spec wait_for_empty_queue(Consumer.t) :: :ok
  defp wait_for_empty_queue(consumer) do
    unless Consumer.queue_empty?(consumer) do
      # Process.sleep(@wait_timeout)
      wait_for_empty_queue(consumer)
    end
    :ok
  end
end
