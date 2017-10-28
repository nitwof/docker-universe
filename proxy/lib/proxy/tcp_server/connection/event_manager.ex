defmodule Proxy.TCPServer.Connection.EventManager do
  @timeout 5_000

  def start_link do
    child = %{id: GenServer, start: {GenServer, :start_link, []}}
    Supervisor.start_link([child], strategy: :simple_one_for_one)
  end

  def stop(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.stop(pid, :normal, @timeout) end)
    Supervisor.stop(sup)
  end

  def add_handler(sup, handler) do
    Supervisor.start_child(sup, handler)
  end

  def message(sup, msg) do
    notify(sup, {:message, msg})
  end

  defp notify(sup, msg) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.cast(pid, msg) end)
  end
end
