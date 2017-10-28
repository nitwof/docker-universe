defmodule Proxy.Producer.TCPMessagesHandler do
  use GenServer

  def handle_cast({:message, msg}, state) do
    IO.puts(msg)
    {:noreply, state}
  end
end
