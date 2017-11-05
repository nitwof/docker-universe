defmodule Proxy.TCPSocket do
  @moduledoc """
  Wrapper for gen_tcp module.
  Provides functions for managing gen_tcp sockets.
  """

  # gen_tcp socket options:
  # - `:binary` - receives data as binaries (instead of lists)
  # - `packet: :line` - receives data line by line
  # - `active: false` - blocks on `:gen_tcp.recv/2` until data is available
  # - `reuseaddr: true` - allows us to reuse the address if the listener crashes

  @type tcp_port :: non_neg_integer

  @doc """
  Sets up a socket to listen on port Port on the local host.

  If Port == 0, the underlying OS assigns an available port number, use inet:port/1 to retrieve it.

  Returns socket or error.
  """
  @spec listen(tcp_port) :: {:ok, :gen_tcp.socket} | {:error, :system_limit | :inet.posix}
  def listen(port) do
    opts = [:binary, packet: :line, active: false, reuseaddr: true]
    :gen_tcp.listen(port, opts)
  end

  @doc """
  Connects to a server on TCP port Port on the host with IP address Address.

  Argument Address can be a hostname or an IP address.

  Returns socket or error.
  """
  @spec connect(String.t, tcp_port) :: {:ok, :gen_tcp.socket} | {:error, :inet.posix}
  def connect(host, port) do
    opts = [:binary, packet: :line, active: false]
    :gen_tcp.connect(String.to_charlist(host), port, opts)
  end

  @doc """
  Accepts an incoming connection request on a listening socket.

  Returns socket or error.
  """
  @spec accept(:gen_tcp.socket) ::
    {:ok, :gen_tcp.socket} |{:error, :closed | :timeout | :system_limit | :inet.posix}
  def accept(socket) do
    :gen_tcp.accept(socket)
  end

  @doc """
  Assigns a new controlling process pid to socket.

  The controlling process is the process that receives messages from the socket.
  """
  @spec controlling_process(:gen_tcp.socket, pid) ::
    :ok | {:error, :closed | :not_owner | :badarg | :inet.posix}
  def controlling_process(socket, pid) do
    :gen_tcp.controlling_process(socket, pid)
  end

  @doc """
  Closes a TCP socket.
  """
  @spec close(:gen_tcp.socket) :: :ok
  def close(socket) do
    :gen_tcp.close(socket)
  end

  @doc """
  Receives a packet from a socket in passive mode.

  Returns data or error.
  """
  @spec read(:gen_tcp.socket) :: {:ok, String.t} | {:error, :closed | :inet.posix}
  def read(socket, timeout \\ :infinity) do
    :gen_tcp.recv(socket, 0, timeout)
  end

  @doc """
  Sends data on a socket.
  """
  @spec write(:gen_tcp.socket, String.t) :: :ok | {:error, :closed | :inet.posix}
  def write(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
