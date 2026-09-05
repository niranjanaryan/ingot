defmodule Ingot.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/niranjanaryan/ingot"

  def project do
    [
      app: :ingot,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      description: "Iroh + Zenoh cluster, BLAKE3/S5 and S3 storage. HTTP/3 is gale.",
      source_url: @source_url,
      name: "Ingot"
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :inets, :ssl, :public_key], mod: {Ingot.Application, []}]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:libcluster, "~> 3.5", optional: true},
      {:flame, "~> 0.5", optional: true},
      {:flame_k8s_backend, "~> 0.6", optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp aliases, do: [test: ["ingot.build", "test"]]

  defp docs do
    [main: "Ingot", extras: ["README.md", "LICENSE", "CHANGELOG.md", "HASH.md"]]
  end

  defp package do
    [
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Dusk" => "https://github.com/niranjanaryan/dusk",
        "Stow" => "https://github.com/niranjanaryan/stow",
        "Gale" => "https://github.com/niranjanaryan/gale",
        "Sponsor" => "https://github.com/sponsors/niranjanaryan"
      },
      files: ~w(lib native/zig Makefile mix.exs README.md LICENSE CHANGELOG.md HASH.md .formatter.exs)
    ]
  end
end
