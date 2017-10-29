defmodule Proxy.CompositeConnection do
  use GenServer

  alias Proxy.Connection

  @cli_group_name "proxy_cli_consumer"
  @app_group_name "proxy_app_consumer"

  def start_link(cli_socket, app_socket, topic, partition) do
    GenServer.start_link(__MODULE__,
      {cli_socket, app_socket, topic, partition},
      name: String.to_atom("#{__MODULE__}_#{topic}_#{partition}")
    )
  end

  def init({cli_socket, app_socket, topic, partition}) do
    with {:ok, cli_conn} <- Connection.start_link(cli_socket, @cli_group_name,
                                                  topic, partition + 1, partition),
         {:ok, app_conn} <- Connection.start_link(app_socket, @app_group_name,
                                                  topic, partition, partition + 1)
    do
      state = %{
        cli_conn: cli_conn,
        app_conn: app_conn
      }
      {:ok, state}
    else
      err ->
        {:error, err}
    end
  end
end
