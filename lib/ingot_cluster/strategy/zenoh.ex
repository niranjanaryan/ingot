defmodule IngotCluster.Strategy.Zenoh do
  @moduledoc """
  libcluster strategy: membership over **Zenoh** (`zenohd`).

      config :libcluster,
        topologies: [
          ingot_zenoh: [
            strategy: IngotCluster.Strategy.Zenoh,
            config: [
              connect: "tcp/127.0.0.1:7447",
              key: "ingot_cluster/cluster/nodes",
              interval: 5_000
            ]
          ]
        ]

  Publishes `Node.self()` on the configured key. Optional `:nodes` seeds
  Erlang distribution when the overlay has already discovered names.
  """
  use GenServer
  require Logger

  alias IngotCluster.Strategy

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    cfg = Strategy.config(opts)
    key = Keyword.get(cfg, :key, "ingot_cluster/cluster/nodes")

    state = %{
      topology: Strategy.topology(opts),
      connect: Strategy.connect_fun(opts),
      disconnect: Strategy.disconnect_fun(opts),
      list_nodes: Strategy.list_nodes_fun(opts),
      config: cfg,
      key: key,
      known: MapSet.new(),
      interval: Strategy.interval(cfg)
    }

    _ = maybe_start_zenoh(cfg)
    {:ok, state, {:continue, :tick}}
  end

  @impl true
  def handle_continue(:tick, state), do: tick(state)

  @impl true
  def handle_info(:tick, state), do: tick(state)

  def handle_info(_msg, state), do: {:noreply, state}

  defp tick(state) do
    self_node = Strategy.node_name()
    payload = Atom.to_string(self_node)

    _ = publish(state.key, payload)

    peers = advertised_peers(state.config)
    new_nodes = Enum.reject(peers, &(&1 == self_node))

    Strategy.connect_nodes(state.topology, state.connect, state.list_nodes, new_nodes)

    :telemetry.execute(
      [:ingot_cluster, :strategy, :zenoh, :tick],
      %{peers: length(new_nodes)},
      %{topology: state.topology, key: state.key}
    )

    Process.send_after(self(), :tick, state.interval)
    {:noreply, %{state | known: MapSet.new(new_nodes)}}
  end

  defp maybe_start_zenoh(cfg) do
    if Process.whereis(IngotCluster.Zenoh) do
      :ok
    else
      opts = [
        connect: Keyword.get(cfg, :connect, "tcp/127.0.0.1:7447"),
        key: Keyword.get(cfg, :key, "ingot_cluster/cluster/**"),
        live: Keyword.get(cfg, :live, false)
      ]

      case IngotCluster.Zenoh.start_link(opts) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        other -> Logger.debug("IngotCluster.Strategy.Zenoh start #{inspect(other)}")
      end
    end
  end

  defp publish(key, payload) do
    if Process.whereis(IngotCluster.Zenoh) do
      IngotCluster.Zenoh.put(key, payload)
    else
      {:error, :not_started}
    end
  rescue
    _ -> {:error, :put_failed}
  end

  defp advertised_peers(cfg) do
    Keyword.get(cfg, :nodes, [])
    |> List.wrap()
    |> Enum.map(fn
      n when is_atom(n) -> n
      n when is_binary(n) -> String.to_atom(n)
    end)
  end
end
