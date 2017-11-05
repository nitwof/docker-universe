defmodule Proxy.AcceptorPool do
  @moduledoc """
  Wraps Task.Supervisor to start acceptors by routes.
  """

  alias Proxy.Acceptor

  @type t :: Supervisor.supervisor
  @type service :: {String.t, non_neg_integer}
  @type routes :: list(
    {non_neg_integer, service}
  )

  @doc """
  Starts Acceptor Pool
  """
  @spec start_link(routes) ::
        {:ok, pid} | {:error, any}
  def start_link(routes, opts \\ []) do
    case Task.Supervisor.start_link(opts) do
      {:ok, pid} ->
        start_acceptors(pid, routes)
        {:ok, pid}
      err -> err
    end
  end

  @doc """
  Starts new acceptor on port
  """
  @spec start_acceptor(t, non_neg_integer, service) :: {:ok, pid}
  def start_acceptor(sup, port, service) do
    Task.Supervisor.start_child(sup, Acceptor, :run, [port, service])
  end

  @doc """
  Starts multiple acceptors
  """
  @spec start_acceptors(t, routes) :: :ok
  def start_acceptors(sup, routes) do
    routes
    |> Enum.each(fn {port, service} ->
      {:ok, _} = start_acceptor(sup, port, service)
    end)
  end
end
