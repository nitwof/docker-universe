defmodule Proxy.Configurator.ServiceConfig do
  @moduledoc """
  Service config struct
  """

  defstruct [:host, :port, :proxy_port, :maintenance]

  alias Proxy.Configurator.ServiceConfig

  @type t :: %ServiceConfig{}

  @doc """
  Checks is service on maintenance
  """
  @spec maintenance?(t) :: boolean
  def maintenance?(%ServiceConfig{maintenance: maintenance}) do
    maintenance
  end
end
