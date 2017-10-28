defmodule Proxy.TCPServer.Connection do
  use GenServer

  alias Proxy.TCPServer.Connection.EventManager
  alias Proxy.TCPServer.Connection.Listener

  # Client
  def start_link([socket, event_handlers]) do
    __MODULE__
    |> GenServer.start_link(%{
      socket: socket,
      event_handlers: event_handlers,
      event_manager: nil,
      listener: nil
    })
  end

  def message(pid, msg) do
    GenServer.call(pid, {:message, msg})
  end

  # Server
  def init(%{socket: socket, event_handlers: handlers} = state) do
    with {:ok, em_pid} <- EventManager.start_link(),
         :ok <- handlers |> Enum.each(
           fn handler -> EventManager.add_handler(em_pid, handler) end
         ),
         {:ok, listener_pid} <- Listener.start_link([socket, em_pid]),
         do: {:ok, %{state | event_manager: em_pid, listener: listener_pid}}
  end

  def handle_call({:message, msg}, _from, %{socket: socket} = state) do
    :gen_tcp.send(socket, msg)
    {:reply, state}
  end
end
