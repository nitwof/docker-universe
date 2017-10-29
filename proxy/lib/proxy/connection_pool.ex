defmodule Proxy.ConnectionPool do
  use Supervisor

  @timeout 5_000

  @topic "test"
  @partition 0
  @host "0.0.0.0"
  @port 2000

  alias Proxy.TCPSocket
  alias Proxy.CompositeConnection

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

  def stop(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.stop(pid, :normal, @timeout) end)
    Supervisor.stop(sup)
  end

  def create_connection(sup, cli_socket) do
    case TCPSocket.connect(@host, @port) do
      {:ok, app_socket} ->
        args = [cli_socket, app_socket, @topic, @partition]
        case Supervisor.start_child(sup, args) do
          {:ok, pid} -> {:ok, pid}
          err ->
            TCPSocket.close(app_socket)
            err
        end
      err -> err
    end
  end
end
