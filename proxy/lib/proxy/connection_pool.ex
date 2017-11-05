defmodule Proxy.ConnectionPool do
  @moduledoc """
  Supervisor that contains all composite connections.
  Don't restart child on their exit.
  Strategy: simple_one_for_one
  """

  use Supervisor

  @type t :: Supervisor.supervisor
  @type service :: {String.t, non_neg_integer}

  @timeout 5_000

  alias Proxy.CompositeConnection

  @doc """
  Starts connection pool
  """
  @spec start_link() :: {:ok | pid} | {:error, any}
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    child = Supervisor.child_spec(CompositeConnection,
      start: {CompositeConnection, :start_link, []},
      restart: :temporary
    )
    Supervisor.init([child], strategy: :simple_one_for_one)
  end

  @doc """
  Stops connection pool
  """
  @spec stop(t) :: :ok
  def stop(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.stop(pid, :normal, @timeout) end)
    Supervisor.stop(sup)
  end

  @doc """
  Creates new connection and appends it to children
  """
  @spec create_connection(t, :gen_tcp.socket, service) ::
        {:ok, pid} | {:error, any}
  def create_connection(sup, cli_socket, service) do
    Supervisor.start_child(sup, [cli_socket, service])
  end
end
