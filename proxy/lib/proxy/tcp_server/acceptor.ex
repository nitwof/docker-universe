defmodule Proxy.TCPServer.Acceptor do
  use Task

  require Logger

  alias Proxy.TCPServer.ConnectionPool

  def start_link([port, connection_pool, event_handlers]) do
    Task.start_link(__MODULE__, :run, [port, connection_pool, event_handlers])
  end

  def run(port, connection_pool, event_handlers) do
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    {:ok, socket} = :gen_tcp.listen(
      port,
      [:binary, packet: :line, active: false, reuseaddr: true]
    )
    Logger.info "Accepting connections on port #{port}"

    loop_acceptor(socket, connection_pool, event_handlers)
  end

  defp loop_acceptor(socket, connection_pool, event_handlers) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = connection_pool
                 |> ConnectionPool.add_connection(client, event_handlers)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket, connection_pool, event_handlers)
  end
end
