defmodule IngotCluster.CLI do
  @moduledoc "Standalone CLI (`ingot_cluster`) and Mix task (`mix ingot_cluster`)."

  @version Mix.Project.config()[:version]

  @help """
  ingot_cluster #{@version} — Iroh + Zenoh cluster

    ingot_cluster backends
    ingot_cluster match PAT KEY
    ingot_cluster hash FILE [--algo blake3|xxh3|hash64]
    ingot_cluster put  FILE
    ingot_cluster nif
    ingot_cluster version
    ingot_cluster stacks peers
    ingot_cluster stacks relay-status
    ingot_cluster flame --overlay stacks

  Install: mix ingot_cluster.install
    Linux/macOS: ~/.local/bin
    Windows:     %LOCALAPPDATA%\\elixcoder\\bin
    Override:    ELIXCODER_BIN
  Hex: {:ingot_cluster, "~> 0.1", hex: :ingot_cluster}
  """

  def main(args), do: main(args, halt: !mix?())

  def main(args, opts) do
    _ = Application.ensure_all_started(:ingot_cluster)

    {parsed, rest, _} =
      OptionParser.parse(args,
        strict: [algo: :string, help: :boolean, version: :boolean],
        aliases: [h: :help, v: :version]
      )

    result =
      cond do
        parsed[:help] == true ->
          info(@help)
          :ok

        parsed[:version] == true or rest == ["version"] ->
          info("ingot_cluster #{@version}")
          :ok

        rest == [] ->
          info(@help)
          :ok

        true ->
          dispatch(rest, parsed)
      end

    finish(result, Keyword.get(opts, :halt, false))
  end

  defp dispatch(["backends" | _], _), do: info(inspect(IngotCluster.backends(), pretty: true))

  defp dispatch(["match", pat, key | _], _) do
    info(inspect(IngotCluster.key_match(pat, key)))
    :ok
  end

  defp dispatch(["hash", file | _], parsed) do
    bin = File.read!(file)

    case parsed[:algo] || "blake3" do
      "blake3" ->
        info(Base.encode16(IngotCluster.blake3(bin), case: :lower))
        :ok

      "xxh3" ->
        info(Integer.to_string(IngotCluster.xxh3(bin)))
        :ok

      "hash64" ->
        info(Integer.to_string(IngotCluster.hash64(bin)))
        :ok

      other ->
        err("unknown algo #{other}")
        {:error, :algo}
    end
  end

  defp dispatch(["put", file | _], _) do
    {:ok, cid} = IngotCluster.Storage.put(File.read!(file))
    info(IngotCluster.Storage.CID.hex(cid))
    :ok
  end

  defp dispatch(["nif" | _], _) do
    info("nif=#{IngotCluster.nif_loaded?()}")
    :ok
  end

  defp dispatch(["stacks", "peers" | _], _) do
    peers = IngotCluster.Stacks.discover_peers()
    info(inspect(peers, pretty: true))
    :ok
  end

  defp dispatch(["stacks", "relay-status" | _], _) do
    {:ok, session} = IngotCluster.Zenoh.session("stacks/sbtc/relay/status")

    info("Subscribed to stacks/sbtc/relay/status (Ctrl+C to exit)")

    # Keep process alive and print messages
    :timer.sleep(:infinity)
  end

  defp dispatch(["flame", "--overlay", "stacks" | _], _) do
    info("Starting FLAME overlay for Stacks...")
    {:ok, _pid} = IngotCluster.Stacks.start_link(overlay: :stacks, backend: :iroh)
    info("FLAME Stacks overlay started")
    :timer.sleep(:infinity)
  end

  defp dispatch(_, _) do
    info(@help)
    :ok
  end

  defp info(msg), do: IO.puts(msg)
  defp err(msg), do: IO.puts(:stderr, msg)

  defp mix? do
    Code.ensure_loaded?(Mix.Project) and function_exported?(Mix.Project, :get, 0)
  rescue
    _ -> false
  end

  defp finish(:ok, false), do: :ok
  defp finish({:error, _} = e, false), do: e
  defp finish(:ok, true), do: System.halt(0)
  defp finish(_, true), do: System.halt(1)
end
