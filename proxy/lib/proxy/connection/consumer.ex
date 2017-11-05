defmodule Proxy.Connection.Consumer do
  @moduledoc """
  GenServer that listens Kafka.
  Sends all received messages to connection (tcp socket).
  """
  use KafkaEx.GenConsumer

  alias Proxy.TCPSocket
  alias KafkaEx.GenConsumer
  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  # Client

  @doc """
  Starts consumer and sets connection
  """
  @spec start_link(:gen_tcp.socket, String.t, String.t, non_neg_integer) ::
        {:ok, pid} | {:error, any}
  def start_link(socket, group_name, topic, partition, opts \\ []) do
    with {:ok, pid} <- GenConsumer.start_link(__MODULE__, group_name,
                                              topic, partition, opts)
    do
      set_socket(pid, socket)
      {:ok, pid}
    end
  end

  @doc """
  Sets connection in GenServer's state
  """
  @spec set_socket(pid, :gen_tcp.socket) :: :ok
  def set_socket(pid, socket) do
    GenConsumer.call(pid, {:set_socket, socket})
  end

  @doc """
  Checks is queue empy
  """
  @spec queue_empty?(pid) :: boolean
  def queue_empty?(pid) do
    # TODO: This should be refactored
    %{current_offset: current_offset,
      committed_offset: committed_offset} = :sys.get_state(pid)
    current_offset == committed_offset
  end

  # Server

  def init(topic, partition) do
    state = %{
      topic: topic,
      partition: partition,
      socket: nil
    }
    {:ok, state}
  end

  def handle_message_set(messages, %{socket: socket, topic: topic,
                                     partition: partition} = state) do
    Enum.each(messages,
      fn msg ->
        Logger.debug fn ->
          "Received message #{inspect(msg)} from Kafka #{topic}:#{partition}"
        end
        Logger.debug fn ->
          "Sending message #{inspect(msg)} to tcp"
        end
      end
    )

    messages
    |> Enum.filter(fn %Message{value: data} -> data != "" end)
    |> Enum.each(fn %Message{value: data} -> TCPSocket.write(socket, data) end)

    {:async_commit, state}
  end
  def handle_message_set(_messages, state), do: {:async_commit, state}

  def handle_call({:set_socket, socket}, _from, state) do
    {:reply, :ok, %{state | socket: socket}}
  end
end
