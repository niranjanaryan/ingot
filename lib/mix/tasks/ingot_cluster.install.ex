defmodule Mix.Tasks.IngotCluster.Install do
  @moduledoc "Install ingot_cluster: Burrito single binary if possible, else escript."
  use Mix.Task
  @shortdoc "Install the ingot_cluster CLI (single binary or escript)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    case maybe_burrito() do
      {:ok, src} ->
        dest = IngotCluster.CLI.Paths.install_bin(src, "ingot_cluster")
        Mix.shell().info("installed single binary #{dest}")

      :error ->
        Mix.Task.run("ingot_cluster.build")
        Mix.Task.run("escript.build")
        dest = IngotCluster.CLI.Paths.install_escript("ingot_cluster")
        priv = IngotCluster.CLI.Paths.copy_priv(:ingot_cluster)
        Mix.shell().info("installed escript #{dest} (needs escript on PATH)")
        Mix.shell().info("NIFs in #{priv}")
        Mix.shell().info("for a single binary: zig 0.15 + xz, then mix ingot_cluster.binary")
    end

    Mix.shell().info("bin dir #{IngotCluster.CLI.Paths.bin_dir()}")
  end

  defp maybe_burrito do
    Mix.Task.run("ingot_cluster.binary")

    case Path.wildcard("burrito_out/ingot_cluster_*") do
      [f | _] -> {:ok, f}
      _ -> :error
    end
  rescue
    e ->
      Mix.shell().error("burrito: #{Exception.message(e)}")
      :error
  end
end
