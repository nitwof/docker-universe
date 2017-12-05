defmodule Proxy.TopicsAllocator do
  @moduledoc """
  Stores allocated topics.
  Allocates topics on request.
  """

  use GenServer

  require Logger

  alias Proxy.Zookeeper

  @type t :: GenServer.server

  @topic_id_len 32

  @doc """
  Generates topic id
  """
  @spec generate_topic_id() :: String.t
  def generate_topic_id do
    generate_hex(@topic_id_len)
  end

  @doc """
  Starts TopicsAllocator
  """
  @spec start_link(t) :: {:ok, pid} | {:error, any}
  def start_link(zk, opts \\ []) do
    GenServer.start_link(__MODULE__, {zk}, opts)
  end

  @spec allocate(t) :: {:ok, String.t}
  def allocate(pid) do
    GenServer.call(pid, :allocate)
  end

  @spec free(t, String.t) :: :ok | {:error, :not_found}
  def free(pid, topic) do
    GenServer.call(pid, {:free, topic})
  end

  def init({zk}) do
    state = %{
      zk: zk,
      topics: []
    }
    {:ok, state}
  end

  def handle_call(:allocate, _from, %{zk: zk, topics: topics} = state) do
    topic = allocate_new_topic(topics)
    delete_topic(zk, topic)
    KafkaEx.produce(topic, 0, "")
    KafkaEx.produce(topic, 1, "")
    Logger.debug fn -> "Allocated topic #{topic}" end
    {:reply, {:ok, topic}, %{state | topics: [topic | topics]}}
  end

  def handle_call({:free, topic}, _from, %{zk: zk, topics: topics} = state) do
    if Enum.member?(topics, topic) do
      delete_topic(zk, topic)
      {:reply, :ok, %{state | topics: List.delete(topics, topic)}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end
 
  @spec allocate_new_topic(list(String.t)) :: String.t
  defp allocate_new_topic(topics) do
    topic = generate_topic_id()
    if Enum.member?(topics, topic) do
      allocate_new_topic(topics)
    else
      topic
    end
  end

  @spec generate_hex(integer) :: String.t
  defp generate_hex(n) do
    n
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  @spec delete_topic(pid, String.t) :: :ok | {:error, any}
  defp delete_topic(zk, topic) do
    case Zookeeper.create(zk, "/admin/delete_topics/#{topic}") do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
