defmodule Proxy.AcceptorPool do
  @moduledoc """
  Wraps Supervisor to start acceptors by routes.
  """

  use Supervisor

  alias Proxy.Acceptor
  alias Proxy.Configurator.ServiceConfig

  @type t :: Supervisor.supervisor
  @type service :: {String.t, non_neg_integer}

  @doc """
  Starts Acceptor Pool
  """
  @spec start_link() :: {:ok, pid} | {:error, any}
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    child = Supervisor.child_spec(Acceptor,
      start: {Acceptor, :start_link, []},
      restart: :permanent
    )
    Supervisor.init([child], strategy: :simple_one_for_one)
  end

  @doc """
  Stops acceptor pool
  """
  @spec stop(t) :: :ok
  def stop(sup) do
    stop_all(sup)
    Supervisor.stop(sup)
  end

  @doc """
  Stops all acceptors
  """
  @spec stop_all(t) :: :ok
  def stop_all(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> Supervisor.terminate_child(sup, pid) end)
  end

  @doc """
  Starts new acceptor by config
  """
  @spec start_acceptor(t, String.t, ServiceConfig.t) :: {:ok, pid}
  def start_acceptor(sup, service, config) do
    Supervisor.start_child(
      sup, [config.proxy_port, service, {config.host, config.port}]
    )
  end

  @doc """
  Stops acceptor
  """
  @spec stop_acceptor(t, pid) :: :ok
  def stop_acceptor(sup, acceptor) do
    Supervisor.terminate_child(sup, acceptor)
  end
end
