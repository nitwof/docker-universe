defmodule Proxy.TCPServer.Connection.Listener do
  use Task

  alias Proxy.TCPServer.Connection.EventManager

  def start_link([socket, events_handler]) do
    Task.start_link(__MODULE__, :run, [socket, events_handler])
  end

  def run(socket, events_handler) do
    case socket |> :gen_tcp.recv(0) do
      {:ok, msg} ->
        EventManager.message(events_handler, msg)
        run(socket, events_handler)
      {:error, _} ->
        exit(:shutdown)
    end
  end
end
