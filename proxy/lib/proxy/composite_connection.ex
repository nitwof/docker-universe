defmodule Proxy.CompositeConnection do
  @moduledoc """
  Supervisor for two connections.
  """
  use GenServer

  require Logger

  alias Proxy.TCPSocket
  alias Proxy.TopicsAllocator
  alias Proxy.Connection

  @type t :: GenServer.server
  @type service :: {String.t, non_neg_integer}
  @type child_spec :: {String.t, module, atom, list}

  @cli_group "proxy_cli_consumer"
  @cli_partition 1
  @app_group "proxy_app_consumer"
  @app_partition 0

  @doc """
  Starts CompositeConnection
  """
  @spec start_link(:gen_tcp.socket, service) :: {:ok, pid} | {:error, any}
  def start_link(cli_socket, service, opts \\ []) do
    GenServer.start_link(__MODULE__, {cli_socket, service}, opts)
  end

  @doc """
  Pauses app connection
  """
  @spec pause_app_conn(t) :: :ok
  def pause_app_conn(server) do
    GenServer.call(server, :pause_app_conn)
  end

  @doc """
  Resumes app connection
  """
  @spec resume_app_conn(t) :: :ok | {:error, any}
  def resume_app_conn(server) do
    GenServer.call(server, :resume_app_conn)
  end

  def init({cli_socket, {host, port} = service}) do
    Process.flag(:trap_exit, true)

    with {:ok, app_socket} <- TCPSocket.connect(host, port),
         {:ok, topic} <- TopicsAllocator.allocate(TopicsAllocator),
         {:ok, cli_conn} <- start_connection(:cli, cli_socket, topic),
         {:ok, app_conn} <- start_connection(:app, app_socket, topic)
    do
      TCPSocket.controlling_process(cli_socket, cli_conn)
      TCPSocket.controlling_process(app_socket, app_conn)
      state = %{
        service: service,
        cli_conn: cli_conn,
        app_conn: app_conn,
        topic: topic
      }
      {:ok, state}
    else
      err ->
        {:error, err}
    end
  end

  def handle_info({:EXIT, from, _reason},
                  %{cli_conn: cli_conn, app_conn: app_conn} = state) do
    require Logger
    case from do
      ^cli_conn ->
        if !app_conn_paused?(state) && Process.alive?(app_conn) do
          Connection.stop(app_conn)
        end
        exit(:normal)
      ^app_conn ->
        if !app_conn_paused?(state) && Process.alive?(cli_conn) do
          Connection.soft_stop(cli_conn)
        end
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_call(:pause_app_conn, _from, %{app_conn: app_conn} = state) do
    unless app_conn_paused?(state) do
      Connection.stop(app_conn)
    end
    {:reply, :ok, %{state | app_conn: nil}}
  end

  def handle_call(:resume_app_conn, _from,
                  %{service: {host, port}, topic: topic} = state) do
    if app_conn_paused?(state) do
      with {:ok, app_socket} <- TCPSocket.connect(host, port),
           {:ok, app_conn} <- start_connection(:app, app_socket, topic)
      do
        TCPSocket.controlling_process(app_socket, app_conn)
        {:reply, :ok, %{state | app_conn: app_conn}}
      else
        err -> {:reply, err, state}
      end
    else
      {:reply, :ok, state}
    end
  end

  def terminate(reason, %{topic: topic}) do
    TopicsAllocator.free(TopicsAllocator, topic)
    Logger.debug "CompositeConnection terminated"
    reason
  end

  @spec start_connection(:cli | :app, :gen_tcp.socket, String.t) ::
        {:ok, pid} | {:error, any}
  defp start_connection(:cli, socket, topic) do
    Connection.start_link(
      socket, @cli_group, topic, @cli_partition, @app_partition
    )
  end
  defp start_connection(:app, socket, topic) do
    Connection.start_link(
      socket, @app_group, topic, @app_partition, @cli_partition
    )
  end

  @spec app_conn_paused?(map) :: boolean
  defp app_conn_paused?(%{app_conn: app_conn}) do
    is_nil(app_conn)
  end
end
