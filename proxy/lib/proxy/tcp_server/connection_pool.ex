defmodule Proxy.TCPServer.ConnectionPool do
  use Supervisor
  @timeout 5_000

  alias Proxy.TCPServer.Connection

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    child = Supervisor.child_spec(Connection, start: {Connection, :start_link, []})
    Supervisor.init([child], strategy: :simple_one_for_one)
  end

  def stop(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.stop(pid, :normal, @timeout) end)
    Supervisor.stop(sup)
  end

  def add_connection(sup, socket, event_handlers) do
    Supervisor.start_child(sup, [[socket, event_handlers]])
  end
end
