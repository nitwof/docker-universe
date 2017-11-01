defmodule Proxy.Connection.Consumer do
  @moduledoc """
  GenServer that listens Kafka.
  Sends all received messages to connection (tcp socket).
  """
  use KafkaEx.GenConsumer

  alias Proxy.Connection
  alias KafkaEx.GenConsumer
  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  # Client

  @doc """
  Starts consumer and sets connection
  """
  @spec start_link(Connection.t, String.t,
                   non_neg_integer, non_neg_integer) :: {:ok, pid} | {:error, any}
  def start_link(conn, group_name, topic, partition, opts \\ []) do
    with {:ok, pid} <- GenConsumer.start_link(__MODULE__, group_name,
                                              topic, partition, opts)
    do
      set_connection(pid, conn)
      {:ok, pid}
    end
  end

  @doc """
  Sets connection in GenServer's state
  """
  @spec set_connection(pid, Connection.t) :: :ok
  def set_connection(pid, conn) do
    GenConsumer.call(pid, {:set_connection, conn})
  end

  # Server

  def init(topic, partition) do
    state = %{
      topic: topic,
      partition: partition,
      conn: nil
    }
    {:ok, state}
  end

  def handle_message_set(messages, %{conn: conn, topic: topic,
                                     partition: partition} = state) do
    Enum.each(messages,
      fn msg -> 
        Logger.debug("Received message '#{inspect(msg)}' from Kafka #{topic}:#{partition}")
      end
    )

    messages
    |> Enum.each(fn %Message{value: data} -> Connection.send_message(conn, data) end)

    {:async_commit, state}
  end
  def handle_message_set(_messages, state), do: {:async_commit, state}

  def handle_call({:set_connection, conn}, _from, state) do
    {:reply, :ok, %{state | conn: conn}}
  end
end
