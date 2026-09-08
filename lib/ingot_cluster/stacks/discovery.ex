defmodule IngotCluster.Stacks.Discovery do
  @moduledoc """
  Stacks node discovery via Iroh DHT for IngotCluster.

  Discovers Stacks signer and API nodes using the Iroh DHT namespace
  `stacks/node/1`. Nodes advertise their IP, port, and version without
  a central tracker.
  """

  alias IngotCluster.Iroh

  @dht_namespace "stacks/node/1"

  @doc """
  Discover Stacks peers from the Iroh DHT.

  Returns a list of peer info maps with `:peer_id`, `:ip`, `:port`, and `:version`.
  """
  def discover(opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)

    case Iroh.dht_get(@dht_namespace, timeout: timeout) do
      {:ok, records} ->
        Enum.map(records, &decode_record/1)

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Advertise this node as a Stacks node in the Iroh DHT.

  Called by Stacks nodes on startup to make themselves discoverable.
  """
  def advertise(node_info) do
    record = encode_record(node_info)
    Iroh.dht_put(@dht_namespace, record)
  end

  defp decode_record(record) when is_binary(record) do
    case :erlang.binary_to_term(record) do
      %{peer_id: peer_id, ip: ip, port: port, version: version} = info ->
        Map.put(info, :peer_id, to_string(peer_id))

      _ ->
        %{}
    end
  rescue
    _ -> %{}
  end

  defp decode_record(_), do: %{}

  defp encode_record(node_info) when is_map(node_info) do
    :erlang.term_to_binary(node_info)
  end
end
