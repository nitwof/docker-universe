# defmodule Proxy.Consumer.Worker do
#   use KafkaEx.GenConsumer

#   alias KafkaEx.GenConsumer
#   alias KafkaEx.Protocol.Fetch.Message

#   require Logger

#   def start_link do
#     GenConsumer.start_link(__MODULE__, "proxy_producer_worker", "test", 0)
#   end

#   def handle_message_set(messages, state) do
#     messages
#     |> Enum.each(fn msg -> Logger.debug(inspect(msg)) end)
#     messages
#     |> Enum.each(fn %Message{value: data} -> Logger.debug("#{__MODULE__}: #{data}") end)
#     messages
#     |> Enum.each(fn %Message{value: data} -> KafkaEx.produce("test", 1, data) end)

#     {:async_commit, state}
#   end
# end
