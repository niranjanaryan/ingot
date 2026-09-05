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
      description: description(),
      source_url: @source_url,
      homepage_url: "https://hex.pm/packages/ingot",
      name: "Ingot"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Ingot.Application, []}
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      # zenohex 0.10 needs rustler_precompiled ~> 0.9; iroh_beam 0.2 pins 0.8.4.
      # Add one in the host app, not both, until those packages align.
      {:zenohex, "~> 0.10", optional: true},
      {:libcluster, "~> 3.5", optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Elixir cluster over Iroh (P2P QUIC) and Zenoh (brokered zenohd). Complements Gale HTTP/3."
  end

  defp docs do
    [
      main: "Ingot",
      source_url: @source_url,
      extras: ["README.md", "LICENSE", "CHANGELOG.md", "FUNDING.md"]
    ]
  end

  defp aliases do
    [
      test: ["ingot.build", "test"],
      bench: ["ingot.build", "ingot.bench"]
    ]
  end

  defp package do
    [
      name: "ingot",
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/niranjanaryan",
        "Gale" => "https://github.com/niranjanaryan/gale"
      },
      files:
        ~w(lib native/zig native/rust/src native/rust/Cargo.toml Makefile mix.exs README.md LICENSE CHANGELOG.md FUNDING.md .formatter.exs)
    ]
  end
end
