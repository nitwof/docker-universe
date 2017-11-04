defmodule Proxy.CompositeConnection do
  @moduledoc """
  Container for two connections.
  Shutdowns on one of the connections exit.
  """
  use GenServer

  alias Proxy.TopicsAllocator
  alias Proxy.Connection

  @cli_group "proxy_cli_consumer"
  @cli_partition 1
  @app_group "proxy_app_consumer"
  @app_partition 0

  @doc """
  Starts CompositeConnection
  """
  @spec start_link(:gen_tcp.socket, :gen_tcp.socket) :: {:ok, pid} | {:error, any}
  def start_link(cli_socket, app_socket, opts \\ []) do
    GenServer.start_link(__MODULE__, {cli_socket, app_socket}, opts)
  end

  def init({cli_socket, app_socket}) do
    with {:ok, topic} = TopicsAllocator.allocate(TopicsAllocator),
         {:ok, cli_conn} <- Connection.start_link(cli_socket, @cli_group, topic,
                                                  @cli_partition, @app_partition),
         {:ok, app_conn} <- Connection.start_link(app_socket, @app_group, topic,
                                                  @app_partition, @cli_partition)
    do
      state = %{
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

  def terminate(reason, %{topic: topic}) do
    TopicsAllocator.free(TopicsAllocator, topic)
    reason
  end
end
