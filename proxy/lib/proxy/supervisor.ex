defmodule Proxy.Supervisor do
  @moduledoc """
  Main supervisor
  """

  use Supervisor

  alias Proxy.Zookeeper
  alias Proxy.TopicsAllocator
  alias Proxy.ConnectionPool
  alias Proxy.AcceptorPool
  alias Proxy.Configurator.Watcher

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Supervisor.child_spec(Zookeeper,
        start: {Zookeeper, :start_link, [zk_hosts(), [name: Zookeeper]]},
        restart: :permanent
      ),
      Supervisor.child_spec(TopicsAllocator,
        start: {TopicsAllocator, :start_link, [Zookeeper, [name: TopicsAllocator]]},
        restart: :permanent
      ),
      {ConnectionPool, name: ConnectionPool},
      {AcceptorPool, name: AcceptorPool},
      Supervisor.child_spec(Watcher,
        start: {Watcher, :start_link, [Zookeeper, "/proxy/services"]},
        restart: :permanent
      ),
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Proxy.Supervisor)
  end

  defp zk_hosts do
    Application.get_env(:proxy, :zk_hosts)
  end
end
