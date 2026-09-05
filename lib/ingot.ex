defmodule Ingot do
  @moduledoc """
  **Iroh** P2P QUIC for Elixir (dial keys, not IPs).

  Zenoh is [Dusk](https://github.com/niranjanaryan/dusk). HTTP/3 is [Gale](https://github.com/niranjanaryan/gale).

      {Ingot, identity: {:file, "data/iroh.identity"}, alpns: ["ingot/1"]}

  Add `{:iroh_beam, "~> 0.2"}` in the **host** app (not here — rustler pin clash with dusk/zenohex).
  """

  defdelegate start_link(opts), to: Ingot.Iroh
  defdelegate child_spec(opts), to: Ingot.Iroh

  def hash64(bin) when is_binary(bin), do: Ingot.Native.hash64(bin)

  def nif_loaded? do
    is_integer(Ingot.Native.hash64("ingot"))
  rescue
    _ -> false
  end
end
