defmodule Proxy.ConnectionPool do
  @moduledoc """
  Supervisor that contains all composite connections.
  Don't restart child on their exit.
  Strategy: simple_one_for_one
  """

  use Supervisor

  @type t :: Supervisor.supervisor
  @type service :: {String.t, non_neg_integer}

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
  Selects connections by service name
  """
  @spec connections_by_service(t, String.t) :: list(pid)
  def connections_by_service(sup, service_name) do
    sup
    |> Supervisor.which_children
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.filter(fn pid ->
      try do
        CompositeConnection.service_name(pid) == service_name
      catch
        :exit, _ -> false
      end
    end)
  end

  @doc """
  Stops connection pool
  """
  @spec stop(t) :: :ok
  def stop(sup) do
    stop_all(sup)
    Supervisor.stop(sup)
  end

  @doc """
  Stops all connections
  """
  @spec stop_all(t) :: :ok
  def stop_all(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> Supervisor.terminate_child(sup, pid) end)
  end
  @spec stop_all(t, list(pid)) :: :ok
  def stop_all(sup, pids) do
    pids
    |> Enum.each(fn pid -> Supervisor.terminate_child(sup, pid) end)
  end

  @doc """
  Pauses all connections
  """
  @spec pause_all(list(pid)) :: :ok
  def pause_all(pids) do
    pids
    |> Enum.each(fn pid -> CompositeConnection.pause_app_conn(pid) end)
  end

  @doc """
  Resumes all connections
  """
  @spec resume_all(list(pid)) :: :ok
  def resume_all(pids) do
    pids
    |> Enum.each(fn pid -> CompositeConnection.resume_app_conn(pid) end)
  end

  @doc """
  Creates new connection and appends it to children
  """
  @spec create_connection(t, :gen_tcp.socket, String.t, service) ::
        {:ok, pid} | {:error, any}
  def create_connection(sup, cli_socket, service_name, service) do
    Supervisor.start_child(sup, [cli_socket, service_name, service])
  end
end
