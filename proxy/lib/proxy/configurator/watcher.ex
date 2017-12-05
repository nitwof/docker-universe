defmodule Proxy.Configurator.Watcher do
  @moduledoc """
  Watches on settings changes in Zookeeper.
  """
  use Task

  require Logger

  alias Proxy.Zookeeper
  alias Proxy.Configurator.ServiceConfig
  alias Proxy.AcceptorPool
  alias Proxy.ConnectionPool

  @type config :: %{String.t => ServiceConfig.t}
  @sleep_timeout 5000

  @doc """
  Starts watcher
  """
  @spec start_link(Zookeeper.t, String.t) :: {:ok, pid} | {:error, any}
  def start_link(zk, base_path) do
    Task.start_link(__MODULE__, :run, [zk, base_path])
  end

  @doc """
  Main task's function
  """
  @spec run(Zookeeper.t, String.t) :: any
  def run(zk, base_path, prev_config \\ %{}) do
    config = fetch_config(zk, base_path)
    if config != prev_config do
      Logger.debug("Configuration has changed. Updating...")
      update_configuration(config, prev_config)
    end
    Process.sleep(@sleep_timeout)
    run(zk, base_path, config)
  end

  @doc """
  Fetch configuration
  """
  @spec fetch_config(Zookeeper.t, String.t) :: config
  def fetch_config(zk, base_path) do
    {:ok, services} = Zookeeper.get_children(zk, base_path)
    services
    |> Enum.map(fn service ->
      {service, fetch_service_config(zk, base_path, service)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Fetchs service's configuration
  """
  @spec fetch_service_config(Zookeeper.t, String.t, String.t) :: ServiceConfig.t
  def fetch_service_config(zk, base_path, service) do
    service_path = Path.join(base_path, service)
    {:ok, host} = Zookeeper.get_data(zk, service_path <> "/host")
    {:ok, port} = Zookeeper.get_data(zk, service_path <> "/port")
    {:ok, proxy_port} = Zookeeper.get_data(zk, service_path <> "/proxy_port")
    {:ok, maintenance} = Zookeeper.get_data(zk, service_path <> "/maintenance")
    %ServiceConfig{
      host: host,
      port: ({value, _} = Integer.parse(port); value),
      proxy_port: ({value, _} = Integer.parse(proxy_port); value),
      maintenance: String.to_existing_atom(maintenance)
    }
  end

  @doc """
  Updates proxy configuration
  """
  @spec update_configuration(config, config | %{}) :: :ok
  def update_configuration(config, prev_config \\ %{}) do
    services = config |> Map.keys() |> MapSet.new
    prev_services = prev_config |> Map.keys() |> MapSet.new

    deleted_services = MapSet.difference(prev_services, services)
    # new_services = MapSet.difference(services, prev_services)
    changed_services = services
    |> MapSet.intersection(prev_services)
    |> Enum.filter(fn service ->
      config |> Map.get(service) |> Map.delete(:maintenance) !=
        prev_config |> Map.get(service) |> Map.delete(:maintenance)
    end)

    AcceptorPool.stop_all(AcceptorPool)

    changed_services
    |> Enum.concat(deleted_services)
    |> Enum.each(fn service ->
      pids = ConnectionPool.connections_by_service(ConnectionPool, service)
      ConnectionPool.stop_all(ConnectionPool, pids)
    end)

    services
    |> Enum.map(fn service -> {service, Map.get(config, service)} end)
    |> Enum.each(fn {service, service_config} ->
      AcceptorPool.start_acceptor(AcceptorPool, service, service_config)
    end)

    # services
    # |> Enum.map(fn service -> {service, Map.get(config, service)} end)
    # |> Enum.each(fn
    #   {service, %{maintenance: true}} ->
    #     ConnectionPool
    #     |> ConnectionPool.connections_by_service(service)
    #     |> ConnectionPool.pause_all()
    #   {service, %{maintenance: false}} ->
    #     ConnectionPool
    #     |> ConnectionPool.connections_by_service(service)
    #     |> ConnectionPool.resume_all()
    #   end
    # )

    :ok
  end
end
