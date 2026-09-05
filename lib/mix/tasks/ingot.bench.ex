defmodule Mix.Tasks.Ingot.Bench do
  @moduledoc false
  use Mix.Task

  @shortdoc "Zig NIF vs Elixir vs Rust key-expr match"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    iters = 80_000
    pat = "ingot/cluster/**"
    key = "ingot/cluster/us-east/node-1"

    unless Ingot.nif_loaded?(), do: Mix.raise("Zig NIF not loaded")

    {zig_us, _} = :timer.tc(fn -> for _ <- 1..iters, do: Ingot.key_match(pat, key) end)
    {elx_us, _} = :timer.tc(fn -> for _ <- 1..iters, do: Ingot.Elixir.key_match(pat, key) end)
    zig = iters * 1_000_000 / zig_us
    elx = iters * 1_000_000 / elx_us

    Mix.shell().info("""
    Ingot key_match #{iters} iters
    Elixir #{round(elx)} /s
    Zig NIF #{round(zig)} /s  (#{Float.round(zig / elx, 2)}×)
    """)
  end
end
