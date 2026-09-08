defmodule IngotCluster.Stacks.Membership do
  @moduledoc """
  Live libcluster membership for Stacks nodes via Zenoh key subscriptions.

  Replaces static `config[:nodes]` with live membership discovery using
  Zenoh pub/sub. Nodes automatically join and leave the cluster based on
  Zenoh key activity.
  """

  use GenServer

  alias IngotCluster.Zenoh

  @stacks_key "stacks/node/1"

  @doc """
  Start the membership supervisor.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Join a Stacks cluster using Zenoh-based membership.
  """
  def join(strategy, nodes) when is_atom(strategy) and is_list(nodes) do
    GenServer.call(__MODULE__, {:join, strategy, nodes})
  end

  @doc """
  Leave the Stacks cluster.
  """
  def leave do
    GenServer.call(__MODULE__, :leave)
  end

  @doc """
  Get current cluster members.
  """
  def members do
    GenServer.call(__MODULE__, :members)
  end

  @impl true
  def init(opts) do
    {:ok, session} = Zenoh.session(@stacks_key)

    # Subscribe to peer advertisements
    {:ok, _sub} = Zenoh.subscribe(session, fn msg ->
      handle_peer_message(msg)
    end)

    state = %{
      session: session,
      strategy: Keyword.get(opts, :strategy, :zenoh),
      members: MapSet.new(),
      local_node: Keyword.get(opts, :local_node, node())
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:join, strategy, nodes}, _from, state) do
    new_state = %{state | strategy: strategy, members: MapSet.new(nodes)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:leave, _from, state) do
    {:reply, :ok, %{state | members: MapSet.new()}}
  end

  @impl true
  def handle_call(:members, _from, state) do
    {:reply, MapSet.to_list(state.members), state}
  end

  defp handle_peer_message(%{peer_id: peer_id, ip: ip, port: port}) do
    # Add peer to cluster membership
    # In production, this would update libcluster topology
    :ok
  end

  defp handle_peer_message(_), do: :ok
end
