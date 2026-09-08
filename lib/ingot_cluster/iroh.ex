defmodule IngotCluster.Iroh do
  @moduledoc "Iroh endpoint wrapper. Optional `iroh_beam`."
  use GenServer
  require Logger

  def available?, do: Code.ensure_loaded?(IrohBeam.Endpoint)

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  def child_spec(opts) do
    %{id: Keyword.get(opts, :name, __MODULE__), start: {__MODULE__, :start_link, [opts]}}
  end

  def endpoint, do: GenServer.call(__MODULE__, :endpoint)

  @impl true
  def init(opts) do
    if available?() do
      start_opts = [
        identity: Keyword.get(opts, :identity, :ephemeral),
        alpns: Keyword.get(opts, :alpns, ["ingot_cluster/1"]),
        network: Keyword.get(opts, :network, :n0)
      ]

      case apply(IrohBeam.Endpoint, :start_link, [start_opts]) do
        {:ok, pid} -> {:ok, %{endpoint: pid}}
        {:error, reason} -> {:stop, reason}
      end
    else
      Logger.warning("iroh_beam not loaded; IngotCluster.Iroh stub")
      {:ok, %{endpoint: nil, stub: true}}
    end
  end

  @impl true
  def handle_call(:endpoint, _from, state) do
    if state[:stub],
      do: {:reply, {:error, :backend_not_loaded}, state},
      else: {:reply, {:ok, state.endpoint}, state}
  end
end
