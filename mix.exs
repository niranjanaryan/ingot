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
      description: "Iroh + Zenoh cluster for Elixir. HTTP/3 is gale; dusk is Zenoh-only.",
      source_url: @source_url,
      name: "Ingot"
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Ingot.Application, []}]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp aliases, do: [test: ["ingot.build", "test"]]

  defp docs do
    [main: "Ingot", extras: ["README.md", "LICENSE", "CHANGELOG.md"]]
  end

  defp package do
    [
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Dusk" => "https://github.com/niranjanaryan/dusk",
        "Gale" => "https://github.com/niranjanaryan/gale",
        "Sponsor" => "https://github.com/sponsors/niranjanaryan"
      },
      files: ~w(lib native/zig Makefile mix.exs README.md LICENSE CHANGELOG.md .formatter.exs)
    ]
  end
end
