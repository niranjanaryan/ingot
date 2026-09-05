defmodule Ingot.Strategy.Zenoh do
  @moduledoc """
  Optional `libcluster` strategy: membership gossip over a Zenoh key.

  Does not form Distributed Erlang by itself. Wire `connect:` to
  `:net_kernel.connect_node` only when you also have a reachable EPMD
  path (or Iroh dist). For CGNAT, stay on Zenoh pub/sub only.
  """

  @behaviour :gen_statem

  def start_link(opts), do: :gen_statem.start_link(__MODULE__, opts, [])

  @impl true
  def callback_mode, do: :handle_event_function

  @impl true
  def init(opts) do
    {:ok, :running, Map.new(opts)}
  end

  @impl true
  def handle_event(_kind, _event, :running, data) do
    {:keep_state, data}
  end
end
