defmodule Proxy.TCPSocket do
  # `:binary` - receives data as binaries (instead of lists)
  # `packet: :line` - receives data line by line
  # `active: false` - blocks on `:gen_tcp.recv/2` until data is available
  # `reuseaddr: true` - allows us to reuse the address if the listener crashes

  def listen(port) do
    opts = [:binary, packet: :line, active: false, reuseaddr: true]
    :gen_tcp.listen(port, opts)
  end

  def connect(host, port) do
    opts = [:binary, packet: :line, active: false]
    :gen_tcp.connect(String.to_charlist(host), port, opts)
  end

  def accept(socket) do
    :gen_tcp.accept(socket)
  end

  def controlling_process(socket, pid) do
    :gen_tcp.controlling_process(socket, pid)
  end

  def close(socket) do
    :gen_tcp.close(socket)
  end

  def read(socket) do
    :gen_tcp.recv(socket, 0)
  end

  def write(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
