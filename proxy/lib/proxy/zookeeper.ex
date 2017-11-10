defmodule Proxy.Zookeeper do
  @moduledoc """
  Wrapper for erlzk
  """

  use GenServer

  alias String.Chars

  @type t :: GenServer.server
  @type host :: {String.t, non_neg_integer}

  @timeout 10_000

  @doc """
  Starts zookeeper client
  """
  @spec start_link(list(host)) ::
        {:ok, pid} | {:error, any}
  def start_link(hosts, opts \\ []) do
    GenServer.start_link(__MODULE__, hosts, opts)
  end

  @doc """
  Creates path in zookeeper
  """
  @spec create(t, String.t) :: {:ok, String.t} | {:error, any}
  def create(pid, path) do
    GenServer.call(pid, {:create, path})
  end

  @doc """
  Returns children of node
  """
  @spec get_children(t, String.t) :: {:ok, list(String.t)} | {:error, any}
  def get_children(pid, path) do
    GenServer.call(pid, {:get_children, path})
  end

  @doc """
  Returns data of property
  """
  @spec get_data(t, String.t) :: {:ok, String.t} | {:error, any}
  def get_data(pid, path) do
    GenServer.call(pid, {:get_data, path})
  end

  def init(hosts) do
    {:ok, pid} = hosts
    |> Enum.map(fn {host, port} -> {String.to_charlist(host), port} end)
    |> :erlzk.connect(@timeout)

    state = %{
      zk_pid: pid
    }
    {:ok, state}
  end

  def handle_call({:create, path}, _from, %{zk_pid: zk_pid} = state) do
    case :erlzk.create(zk_pid, path) do
      {:ok, res} ->
        {:reply, {:ok, Chars.to_string(res)}, state}
      err ->
        {:reply, err, state}
    end
  end

  def handle_call({:get_children, path}, _from, %{zk_pid: zk_pid} = state) do
    case :erlzk.get_children(zk_pid, path) do
      {:ok, children} ->
        {:reply, {:ok, children |> Enum.map(&(Chars.to_string/1))}, state}
      err ->
        {:reply, err, state}
    end
  end

  def handle_call({:get_data, path}, _from, %{zk_pid: zk_pid} = state) do
    case :erlzk.get_data(zk_pid, path) do
      {:ok, {data, _stat}} ->
        {:reply, {:ok, data}, state}
      err ->
        {:reply, err, state}
    end
  end
end
