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
      escript: [main_module: Ingot.CLI, name: "ingot"],
      docs: docs(),
      package: package(),
      description: "Iroh + Zenoh cluster, BLAKE3/S5 and S3 storage. HTTP/3 is gale.",
      source_url: @source_url,
      homepage_url: "https://hex.pm/packages/ingot_cluster",
      name: "Ingot"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl, :public_key],
      mod: {Ingot.Application, []}
    ]
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

  defp aliases,
    do: [
      test: ["ingot.build", "test"],
      bench: ["ingot.build", "ingot.bench"],
      "ingot.cli": ["ingot.build", "escript.build"]
    ]

  defp docs do
    [
      main: "Ingot",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "HASH.md",
        "FUNDING.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "benchmark/RESULTS.md"
      ]
    ]
  end

  defp package do
    [
      name: "ingot_cluster",
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "HexDocs" => "https://hexdocs.pm/ingot_cluster",
        "Dusk" => "https://github.com/niranjanaryan/dusk",
        "Orian" => "https://github.com/niranjanaryan/orian",
        "Gale" => "https://github.com/niranjanaryan/gale",
        "Zeiroh" => "https://github.com/niranjanaryan/zeiroh",
        "Sponsor" => "https://github.com/sponsors/niranjanaryan"
      },
      files:
        ~w(lib native/zig Makefile mix.exs README.md LICENSE CHANGELOG.md HASH.md FUNDING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md benchmark/RESULTS.md .formatter.exs)
    ]
  end
end
