defmodule IngotCluster.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/niranjanaryan/ingot_cluster"

  def project do
    [
      app: :ingot_cluster,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      escript: [main_module: IngotCluster.CLI, name: "ingot_cluster"],
      releases: releases(),
      docs: docs(),
      package: package(),
      description: "Iroh + Zenoh cluster, BLAKE3/S5 and S3 storage. HTTP/3 is gale.",
      source_url: @source_url,
      homepage_url: "https://hex.pm/packages/ingot_cluster",
      name: "IngotCluster"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl, :public_key],
      mod: {IngotCluster.Application, []}
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:libcluster, "~> 3.5", optional: true},
      {:flame, "~> 0.5", optional: true},
      {:flame_k8s_backend, "~> 0.6", optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:burrito, "~> 1.6", optional: true, runtime: false}
    ]
  end

  defp aliases,
    do: [
      test: ["ingot_cluster.build", "test"],
      bench: ["ingot_cluster.build", "ingot_cluster.bench"],
      "ingot_cluster.cli": ["ingot_cluster.build", "escript.build"]
    ]

  def wrap(%Mix.Release{} = release) do
    if Code.ensure_loaded?(Burrito), do: Burrito.wrap(release), else: release
  end

  defp releases do
    [
      ingot_cluster: [
        steps: [:assemble, &__MODULE__.wrap/1],
        burrito: [targets: burrito_targets()]
      ]
    ]
  end

  defp burrito_targets do
    [
      macos: [os: :darwin, cpu: :x86_64, skip_nifs: true],
      macos_silicon: [os: :darwin, cpu: :aarch64, skip_nifs: true],
      linux: [os: :linux, cpu: :x86_64, skip_nifs: true],
      linux_aarch64: [os: :linux, cpu: :aarch64, skip_nifs: true],
      windows: [os: :windows, cpu: :x86_64, skip_nifs: true]
    ]
  end

  defp docs do
    [
      main: "IngotCluster",
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
