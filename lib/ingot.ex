defmodule Ingot do
  @moduledoc """
  Cluster Elixir nodes over **Iroh** (P2P QUIC, dial keys) and **Zenoh**
  (brokered pub/sub via `zenohd`).

  This is not Phoenix HTTP. Use [Gale](https://github.com/niranjanaryan/gale)
  for HTTP/3. Ingot is the **cluster bus**.

      # mix.exs
      {:ingot, "~> 0.1"},
      {:zenohex, "~> 0.10"},   # optional, brokered
      {:iroh_beam, "~> 0.2"}   # optional, P2P

      {Ingot.Cluster,
       zenoh: [connect: "tcp/127.0.0.1:7447", key: "ingot/cluster/**"],
       iroh: [identity: {:file, "data/iroh.identity"}, alpns: ["ingot/1"]]}

  ## Modes

  * **`:zenoh`** — nodes are Zenoh *clients*; a `zenohd` router is the broker
    (MQTT-shaped, works across NAT if the router is public).
  * **`:iroh`** — nodes dial Iroh *endpoint IDs*; hole punch + n0 relay.
    Optional OTP 29 `-proto_dist iroh` is `iroh_beam`, not this package.

  Backends are optional Hex deps. Without them, `Ingot` still starts and
  reports `{:error, :backend_not_loaded}`.
  """

  def backends do
    [
      zenoh: Ingot.Zenoh.available?(),
      iroh: Ingot.Iroh.available?(),
      zig_nif: nif_loaded?(),
      libcluster: Code.ensure_loaded?(Cluster.Supervisor)
    ]
  end

  def key_match(pat, key) when is_binary(pat) and is_binary(key) do
    Ingot.Native.key_match(pat, key)
  end

  def hash64(bin) when is_binary(bin), do: Ingot.Native.hash64(bin)

  def nif_loaded? do
    Ingot.Native.key_match("a", "a") == true
  rescue
    _ -> false
  end
end
