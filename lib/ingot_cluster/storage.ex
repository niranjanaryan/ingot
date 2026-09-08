defmodule IngotCluster.Storage do
  @moduledoc """
  Content-addressed blobs: **BLAKE3** identity, **XXH3** fast checksum.

  Backends: `:memory`, `:s3` (location-addressed + blake3 metadata), `:s5`
  (S5 blob CID over HTTP).
  """

  @table :ingot_storage_memory

  def put(data, opts \\ []) when is_binary(data) do
    if Keyword.get(opts, :backend, :memory) in [:s3, :s5] and orian?() do
      apply(Orian, :put, [data, opts])
    else
      do_put(data, opts)
    end
  end

  defp do_put(data, opts) do
    cid = IngotCluster.Storage.S5.cid(data)
    xxh = IngotCluster.xxh3(data)

    case Keyword.get(opts, :backend, :memory) do
      :memory ->
        ensure_table()
        :ets.insert(@table, {cid.hash, data, cid.size, xxh})
        {:ok, cid}

      :s3 ->
        IngotCluster.Storage.S3.put(data, Keyword.put(opts, :cid, cid))

      :s5 ->
        IngotCluster.Storage.S5.put(data, Keyword.put(opts, :cid, cid))
    end
  end

  def get(cid, opts \\ [])

  def get(%IngotCluster.Storage.CID{hash: hash} = cid, opts) do
    if Keyword.get(opts, :backend, :memory) in [:s3, :s5] and orian?() do
      apply(Orian, :get, [hash, opts])
    else
      do_get(hash, cid, opts)
    end
  end

  def get(hash, opts) when is_binary(hash) and byte_size(hash) == 32 do
    get(%IngotCluster.Storage.CID{hash: hash, size: nil, algo: :blake3}, opts)
  end

  defp do_get(hash, cid, opts) do
    case Keyword.get(opts, :backend, :memory) do
      :memory ->
        ensure_table()

        case :ets.lookup(@table, hash) do
          [{^hash, data, _, _}] -> verify(data, cid)
          [] -> {:error, :not_found}
        end

      :s3 ->
        IngotCluster.Storage.S3.get(cid, opts)

      :s5 ->
        IngotCluster.Storage.S5.get(cid, opts)
    end
  end

  def verify(data, %IngotCluster.Storage.CID{hash: hash}) when is_binary(data) do
    if IngotCluster.blake3(data) == hash, do: {:ok, data}, else: {:error, :integrity}
  end

  defp orian? do
    Code.ensure_loaded?(Orian) and function_exported?(Orian, :put, 2)
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, :set])
      _ -> @table
    end
  end
end
