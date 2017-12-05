defmodule Proxy.CompositeConnection do
  @moduledoc """
  Supervisor for two connections.
  """
  use GenServer

  require Logger

  alias Proxy.TCPSocket
  alias Proxy.Connection

  @type t :: GenServer.server
  @type service :: {String.t, non_neg_integer}
  @type child_spec :: {String.t, module, atom, list}

  @topic_len 32
  @cli_group "proxy_cli_consumer"
  @cli_partition 1
  @app_group "proxy_app_consumer"
  @app_partition 0

  @doc """
  Starts CompositeConnection
  """
  @spec start_link(:gen_tcp.socket, String.t, service) :: {:ok, pid} | {:error, any}
  def start_link(cli_socket, service_name, service, opts \\ []) do
    GenServer.start_link(__MODULE__, {cli_socket, service_name, service}, opts)
  end

  @doc """
  Returns service name
  """
  @spec service_name(t) :: String.t
  def service_name(server) do
    GenServer.call(server, :service_name)
  end

  def init({cli_socket, service_name, {host, port} = service}) do
    Process.flag(:trap_exit, true)

    topic = generate_topic()
    KafkaEx.produce(topic, 0, "")
    with {:ok, app_socket} <- TCPSocket.connect(host, port),
         {:ok, cli_conn} <- start_connection(:cli, cli_socket, topic),
         {:ok, app_conn} <- start_connection(:app, app_socket, topic)
    do
      state = %{
        service_name: service_name,
        service: service,
        cli_conn: cli_conn,
        app_conn: app_conn,
        topic: topic
      }
      {:ok, state}
    else
      err -> {:error, err}
    end
  end

  def handle_info({:EXIT, from, _reason},
                  %{cli_conn: cli_conn, app_conn: app_conn} = state) do
    %Connection{listener: cli_listener, consumer: cli_consumer} = cli_conn
    %Connection{listener: app_listener, consumer: app_consumer} = app_conn
    case from do
      x when x in [cli_listener, cli_consumer] ->
        Logger.debug fn -> "Cli connection terminated" end
        Connection.stop(app_conn)
        exit(:normal)
      x when x in [app_listener, app_consumer] ->
        Logger.debug fn -> "App connection terminated" end
        Connection.soft_stop(cli_conn)
        exit(:normal)
      _ ->
        {:noreply, state}
    end
  end

  def handle_call(:service_name, _from, %{service_name: service_name} = state) do
    {:reply, service_name, state}
  end

  @spec start_connection(:cli | :app, :gen_tcp.socket, String.t) ::
        {:ok, pid} | {:error, any}
  defp start_connection(:cli, socket, topic) do
    Connection.start(
      socket, @cli_group, topic, @cli_partition, @app_partition
    )
  end
  defp start_connection(:app, socket, topic) do
    Connection.start(
      socket, @app_group, topic, @app_partition, @cli_partition
    )
  end

  @spec generate_topic() :: String.t
  defp generate_topic do
    generate_hex(@topic_len)
  end

  @spec generate_hex(integer) :: String.t
  defp generate_hex(n) do
    n
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
