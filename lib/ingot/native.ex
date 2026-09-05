defmodule Ingot.Native do
  @moduledoc "Zig NIF: Zenoh key-expr match and FNV-1a hash64."

  @on_load :load_nif

  def load_nif do
    path =
      case :code.priv_dir(:ingot) do
        {:error, _} -> Path.expand("../../priv/ingot_nif", __DIR__)
        dir -> Path.join(dir, "ingot_nif")
      end

    :erlang.load_nif(String.to_charlist(path), 0)
  rescue
    _ -> :ok
  end

  def key_match(_pat, _key), do: :erlang.nif_error(:nif_not_loaded)
  def hash64(_bin), do: :erlang.nif_error(:nif_not_loaded)
end
