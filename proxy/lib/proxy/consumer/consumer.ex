defmodule Proxy.Consumer do
  use Supervisor

  alias Proxy.Consumer
  alias Proxy.Consumer.Worker

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      worker(Worker)
    ]

    Supervisor.init(children, strategy: :one_for_one, name: Consumer.Supervisor)
  end
end
