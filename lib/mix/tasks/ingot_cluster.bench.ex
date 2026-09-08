defmodule Mix.Tasks.IngotCluster.Bench do
  @moduledoc false
  use Mix.Task
  @shortdoc "Zig NIF key_match / BLAKE3 / XXH3"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    unless IngotCluster.nif_loaded?(), do: Mix.raise("Zig NIF not loaded")

    iters = 80_000
    pat = "ingot_cluster/cluster/**"
    key = "ingot_cluster/cluster/us-east/node-1"
    blob = :crypto.strong_rand_bytes(1024)

    {km_us, _} = :timer.tc(fn -> for _ <- 1..iters, do: IngotCluster.key_match(pat, key) end)
    km = iters * 1_000_000 / km_us

    n = 20_000
    {b3_us, _} = :timer.tc(fn -> for _ <- 1..n, do: IngotCluster.blake3(blob) end)
    {x_us, _} = :timer.tc(fn -> for _ <- 1..n, do: IngotCluster.xxh3(blob) end)
    {h_us, _} = :timer.tc(fn -> for _ <- 1..n, do: IngotCluster.hash64(blob) end)
    b3 = n * 1024 / 1_048_576 / (b3_us / 1_000_000)
    xx = n * 1024 / 1_048_576 / (x_us / 1_000_000)
    h64 = n * 1024 / 1_048_576 / (h_us / 1_000_000)

    body = """
    # IngotCluster bench

    Machine: #{:erlang.system_info(:system_architecture)} OTP #{:erlang.system_info(:otp_release)}
    Date: #{Date.utc_today()}

    | op | rate |
    | --- | ---: |
    | key_match Zig | #{round(km)} /s |
    | blake3 1 KiB | #{:erlang.float_to_binary(b3, decimals: 1)} MiB/s |
    | xxh3 1 KiB | #{:erlang.float_to_binary(xx, decimals: 1)} MiB/s |
    | hash64 FNV 1 KiB | #{:erlang.float_to_binary(h64, decimals: 1)} MiB/s |
    """

    File.mkdir_p!("benchmark")
    File.write!("benchmark/RESULTS.md", body)
    Mix.shell().info(body)
  end
end
