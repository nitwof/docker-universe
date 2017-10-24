defmodule Proxy.Producer.Worker do
  use KafkaEx.GenConsumer

  alias KafkaEx.GenConsumer
  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  def start_link(socket)
    GenConsumer.start_link(__MODULE__, "proxy_producer_worker", "test", 1)
  end

  def handle_message_set(messages, state) do
    messages
    |> Enum.each(fn msg -> Logger.debug(inspect(msg)) end)
    messages
    |> Enum.each(fn %Message{value: data} -> Logger.debug("#{__MODULE__}: #{data}") end)

    {:async_commit, state}
  end
end
