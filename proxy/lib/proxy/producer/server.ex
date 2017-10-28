# defmodule Proxy.Producer.Server do
#   require Logger

#   alias Proxy.Producer.Server
#   alias Proxy.Producer.Worker

#   @doc """
#   Starts accepting connections on the given `port`.
#   """
#   def accept(port) do
#     # 1. `:binary` - receives data as binaries (instead of lists)
#     # 2. `packet: :line` - receives data line by line
#     # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
#     # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
#     {:ok, socket} = :gen_tcp.listen(
#       port,
#       [:binary, packet: :line, active: false, reuseaddr: true]
#     )
#     Logger.info "Accepting connections on port #{port}"
#     loop_acceptor(socket)
#   end

#   defp loop_acceptor(socket) do
#     {:ok, client} = :gen_tcp.accept(socket)
#     {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor,
#       fn ->
#         Worker.start_link(client)
#         serve(client)
#       end
#     )
#     :ok = :gen_tcp.controlling_process(client, pid)
#     loop_acceptor(socket)
#   end

#   defp serve(socket) do
#     data = socket |> read_line()
#     KafkaEx.produce("test", 0, data)
#     KafkaEx.stream("test", 1) |> Enum.take(0) |> inspect |> IO.puts 
#     # socket |> write_line(data)

#     serve(socket)
#   end

#   defp read_line(socket) do
#     {:ok, data} = :gen_tcp.recv(socket, 0)
#     data
#   end

#   defp write_line(socket, line) do
#     :gen_tcp.send(socket, line)
#   end
# end
