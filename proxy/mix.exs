defmodule Proxy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :proxy,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls, test_task: "espec"],
      preferred_cli_env: [espec: :test, coveralls: :test,
                          "coveralls.detail": :test, "coveralls.post": :test,
                          "coveralls.html": :test],
      name: "Proxy",
      source_url: "https://github.com/NightWolf007/docker-universe",
      docs: [main: "Proxy", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Proxy, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kafka_ex, "~> 0.8"},
      {:observer_cli, "~> 1.1.0"},
      {:wobserver, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:espec, "~> 1.4", only: :test},
      {:excoveralls, "~> 0.7", only: :test}
    ]
  end
end
