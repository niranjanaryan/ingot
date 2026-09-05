defmodule Ingot.Iroh do
  @moduledoc """
  Iroh P2P QUIC endpoint (dial keys, not IPs).

  Requires optional `{:iroh_beam, "~> 0.2"}`. Does **not** start Erlang
  distribution; see `iroh_beam` for `-proto_dist iroh`.
  """
  use GenServer
  require Logger

  def available? do
    Code.ensure_loaded?(IrohBeam.Endpoint)
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def endpoint, do: GenServer.call(__MODULE__, :endpoint)

  @impl true
  def init(opts) do
    if available?() do
      start_opts = [
        identity: Keyword.get(opts, :identity, :ephemeral),
        alpns: Keyword.get(opts, :alpns, ["ingot/1"]),
        network: Keyword.get(opts, :network, :n0)
      ]

      case apply(IrohBeam.Endpoint, :start_link, [start_opts]) do
        {:ok, pid} ->
          Logger.info("Ingot.Iroh endpoint up alpns=#{inspect(start_opts[:alpns])}")
          {:ok, %{endpoint: pid}}

        {:error, reason} ->
          {:stop, reason}
      end
    else
      Logger.warning("iroh_beam not loaded; Ingot.Iroh is a stub")
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
