defmodule Proxy do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Proxy.Supervisor.start_link(name: Proxy.Supervisor)
  end
end
