defmodule Proxy.TCPSocketSpec do
  use ESpec

  describe ".listen/1" do
    let :port, do: 8080
    let :opts, do: [:binary, packet: :line, active: false, reuseaddr: true]

    let :socket, do: "socket"

    it "calls gen_tcp listen" do
      allow :gen_tcp |> to(accept :listen,
        fn (p, o) ->
          expect p |> to(eq port())
          expect o |> to(eq opts())
          socket()
        end,
        [:unstick]
      )
      expect described_module().listen(port()) |> to(eq socket())
    end
  end
end
