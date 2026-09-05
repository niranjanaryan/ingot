defmodule Ingot.Strategy.Iroh do
  @moduledoc """
  libcluster strategy: membership over **Iroh** (iron / P2P QUIC).

      config :libcluster,
        topologies: [
          ingot_iroh: [
            strategy: Ingot.Strategy.Iroh,
            config: [
              interval: 5_000,
              alpns: ["ingot/1"]
            ]
          ]
        ]

  Starts `Ingot.Iroh` if it is not already running. Node names are
  hashed with the Zig NIF and advertised as the local identity.
  """
  use GenServer
  require Logger

  alias Ingot.Strategy

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    cfg = Strategy.config(opts)
    state = %{
      topology: Strategy.topology(opts),
      connect: Strategy.connect_fun(opts),
      disconnect: Strategy.disconnect_fun(opts),
      list_nodes: Strategy.list_nodes_fun(opts),
      config: cfg,
      known: MapSet.new(),
      interval: Strategy.interval(cfg)
    }

    _ = maybe_start_iroh(cfg)
    {:ok, state, {:continue, :tick}}
  end

  @impl true
  def handle_continue(:tick, state), do: tick(state)

  @impl true
  def handle_info(:tick, state), do: tick(state)

  def handle_info(_msg, state), do: {:noreply, state}

  defp tick(state) do
    self_node = Strategy.node_name()
    _ = Ingot.hash64(Atom.to_string(self_node))

    peers = advertised_peers(state.config)
    new_nodes = Enum.reject(peers, &(&1 == self_node))

    Strategy.connect_nodes(state.topology, state.connect, state.list_nodes, new_nodes)

    :telemetry.execute(
      [:ingot, :strategy, :iroh, :tick],
      %{peers: length(new_nodes)},
      %{topology: state.topology}
    )

    Process.send_after(self(), :tick, state.interval)
    {:noreply, %{state | known: MapSet.new(new_nodes)}}
  end

  defp maybe_start_iroh(cfg) do
    if Process.whereis(Ingot.Iroh) do
      :ok
    else
      opts = [alpns: Keyword.get(cfg, :alpns, ["ingot/1"])]
      case Ingot.Iroh.start_link(opts) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        other -> Logger.debug("Ingot.Strategy.Iroh iroh start #{inspect(other)}")
      end
    end
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
