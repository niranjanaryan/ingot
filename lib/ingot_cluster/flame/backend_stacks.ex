defmodule IngotCluster.FLAME.Backend.Stacks do
  @moduledoc """
  Stacks-specific FLAME backend for IngotCluster.

  Provides distributed worker orchestration for Stacks indexers and
  sBTC relay monitors using Iroh/Zenoh for auto-discovery.
  """

  @behaviour FLAME.Backend

  alias IngotCluster.{Iroh, Zenoh, Stacks}

  @impl true
  def init(opts) do
    overlay = Keyword.get(opts, :overlay, :stacks)
    backend = Keyword.get(opts, :backend, :iroh)

    case backend do
      :iroh ->
        iroh_opts = Keyword.merge(opts, alpns: ["stacks/node/1", "stacks/relay/1"], overlay: overlay)
        {:ok, _pid} = IngotCluster.Iroh.start_link(iroh_opts)

      :zenoh ->
        zenoh_opts = Keyword.merge(opts, overlay: overlay)
        {:ok, _pid} = IngotCluster.Zenoh.start_link(zenoh_opts)

      _ ->
        {:error, {:unsupported_backend, backend}}
    end
  end

  @impl true
  def spawn_worker(spec) when is_map(spec) do
    # Discover available workers via Iroh DHT
    peers = Stacks.discover_peers()

    case peers do
      {:ok, []} ->
        # No peers found, spawn locally
        FLAME.LocalBackend.spawn_worker(spec)

      {:ok, available_peers} ->
        # Select best peer based on latency/region
        selected = select_peer(available_peers)
        spawn_remote(selected, spec)

      {:error, _} ->
        # Fallback to local
        FLAME.LocalBackend.spawn_worker(spec)
    end
  end

  @impl true
  def terminate_worker(worker_id) do
    # Terminate worker via Iroh/Zenoh
    :ok
  end

  @impl true
  def list_workers do
    # List workers via Iroh/Zenoh
    {:ok, []}
  end

  defp select_peer(peers) do
    # Simple selection: first available peer
    # In production, use latency/region-based selection
    List.first(peers) || %{}
  end

  defp spawn_remote(%{ip: ip, port: port}, spec) do
    # Spawn worker on remote node via FLAME
    # In production, use FLAME over Iroh bootstrap tickets
    FLAME.LocalBackend.spawn_worker(spec)
  end

  defp spawn_remote(_, spec) do
    # No valid peer, spawn locally
    FLAME.LocalBackend.spawn_worker(spec)
  end
end
