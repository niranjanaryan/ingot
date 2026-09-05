defmodule Ingot do
  @moduledoc """
  Cluster over **Iroh** (P2P QUIC / iron) and **Zenoh** (brokered `zenohd`).

  HTTP/3 stays [Gale](https://github.com/niranjanaryan/gale).
  Zenoh-only package is [Dusk](https://github.com/niranjanaryan/dusk).

      {Ingot,
       iroh: [alpns: ["ingot/1"]],
       zenoh: [connect: "tcp/127.0.0.1:7447"]}

  Host app: `{:iroh_beam, "~> 0.2"}` and/or `{:zenohex, "~> 0.10"}` — not both
  until rustler_precompiled pins align. Zig NIF: `key_match/2`, `hash64/1`.

  libcluster: `Ingot.Strategy.Iroh`, `Ingot.Strategy.Zenoh`.
  Phoenix FLAME: `Ingot.FLAME.Backend` with `overlay: :iroh | :zenoh | :both`
  and `provisioner: :local | :docker | :fly | :k8s | :ec2`.
  """

  defdelegate start_link(opts), to: Ingot.Cluster
  defdelegate child_spec(opts), to: Ingot.Cluster

  def key_match(pat, key) when is_binary(pat) and is_binary(key),
    do: Ingot.Native.key_match(pat, key)

  def hash64(bin) when is_binary(bin), do: Ingot.Native.hash64(bin)

  def blake3(bin) when is_binary(bin), do: Ingot.Native.blake3(bin)

  def xxh3(bin) when is_binary(bin), do: Ingot.Native.xxh3(bin)

  def nif_loaded? do
    Ingot.Native.key_match("a", "a") == true
  rescue
    _ -> false
  end

  def backends do
    %{
      iroh: Ingot.Iroh.available?(),
      zenoh: Ingot.Zenoh.available?(),
      zig_nif: nif_loaded?(),
      provisioners: Ingot.Provisioner.status()
    }
  end
end
