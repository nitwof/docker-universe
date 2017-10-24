defmodule Proxy.Supervisor do
  use Supervisor

  alias Proxy.Producer
  alias Proxy.Consumer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Producer,
      Consumer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
