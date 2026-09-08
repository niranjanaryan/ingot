defmodule IngotCluster.Native do
  @moduledoc "Zig NIF: FNV-1a hash64 for endpoint/payload ids."
  @on_load :load_nif

  def load_nif do
    Enum.find_value(nif_candidates(), fn path ->
      case :erlang.load_nif(String.to_charlist(path), 0) do
        :ok -> true
        {:error, _} -> false
      end
    end)

    :ok
  rescue
    _ -> :ok
  end

  defp nif_candidates do
    _ = Code.ensure_loaded(IngotCluster.CLI.Paths)

    app =
      case :code.priv_dir(:ingot_cluster) do
        {:error, _} -> []
        dir -> [Path.join(dir, "ingot_cluster_nif")]
      end

    env = System.get_env("INGOT_CLUSTER_PRIV")
    env = if env, do: [Path.join(env, "ingot_cluster_nif")], else: []

    app ++
      env ++
      IngotCluster.CLI.Paths.nif_dirs(:ingot_cluster, "ingot_cluster_nif") ++
      [Path.expand("../../priv/ingot_cluster_nif", __DIR__)]
  end

  def hash64(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def key_match(_pat, _key), do: :erlang.nif_error(:nif_not_loaded)
  def blake3(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def xxh3(_bin), do: :erlang.nif_error(:nif_not_loaded)
end
