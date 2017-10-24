defmodule Proxy.TCPServer.EventManager do
  @timeout 10_000

  def start_link() do
    import Supervisor.Spec
    Supervisor.start_link([], strategy: :simple_one_for_one)
  end

  def stop(sup) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.stop(pid, :normal, @timeout) end)
    Supervisor.stop(sup)
  end

  def add_handler(sup, handler, opts) do
    sup |> Supervisor.start_child([handler, opts])
  end

  def message(sup, msg) do
    sup |> notify({:message, msg})
  end

  defp notify(sup, msg) do
    sup
    |> Supervisor.which_children
    |> Enum.each(fn {_, pid, _, _} -> GenServer.cast(pid, msg) end)
  end
end
