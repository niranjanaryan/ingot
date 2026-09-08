defmodule IngotCluster.Stacks do
  @moduledoc """
  Stacks-specific coordination layer for IngotCluster.

  Provides Iroh DHT-backed node discovery, Zenoh pub/sub for distributed
  coordination, and libcluster strategies for Stacks node clusters.

  ## Examples

      # Start IngotCluster with Stacks overlay
      {:ok, _pid} = IngotCluster.start_link(
        overlay: :stacks,
        backend: :iroh,
        iroh: [alpns: ["stacks/node/1", "stacks/relay/1"]]
      )

      # Discover Stacks nodes
      {:ok, peers} = IngotCluster.Stacks.discover_peers()

      # Join Stacks cluster via libcluster
      {:ok, _} = IngotCluster.join_cluster(:stacks, [:"stacks-node@host1", :"stacks-node@host2"])
  """

  alias IngotCluster.{Iroh, Zenoh}
  alias IngotCluster.Stacks.{Discovery, Membership}

  @stacks_alpns ["stacks/node/1", "stacks/relay/1"]

  @doc """
  Start IngotCluster with Stacks overlay configuration.
  """
  def start_link(opts) do
    backend = Keyword.get(opts, :backend, :iroh)
    overlay = Keyword.get(opts, :overlay, :stacks)

    case backend do
      :iroh ->
        iroh_opts = Keyword.merge(opts, alpns: @stacks_alpns, overlay: overlay)
        IngotCluster.Iroh.start_link(iroh_opts)

      :zenoh ->
        zenoh_opts = Keyword.merge(opts, overlay: overlay)
        IngotCluster.Zenoh.start_link(zenoh_opts)

      _ ->
        {:error, {:unsupported_backend, backend}}
    end
  end

  @doc """
  Discover Stacks peers via Iroh DHT.
  """
  def discover_peers(opts \\ []) do
    Discovery.discover(opts)
  end

  @doc """
  Join a Stacks cluster using libcluster strategies.

  Uses Zenoh key subscriptions for live membership instead of static node lists.
  """
  def join_cluster(strategy, nodes) when is_atom(strategy) and is_list(nodes) do
    Membership.join(strategy, nodes)
  end

  @doc """
  Leave the Stacks cluster.
  """
  def leave_cluster do
    Membership.leave()
  end

  @doc """
  Get current cluster members.
  """
  def cluster_members do
    Membership.members()
  end
end
