defmodule Ingot.Elixir do
  @moduledoc "Pure-Elixir fallbacks for benches when the NIF is absent."

  def key_match(pat, key) when is_binary(pat) and is_binary(key) do
    match(pat, key)
  end

  defp match("", ""), do: true
  defp match("", _), do: false

  defp match(<<"**", rest::binary>>, key) do
    rest = String.trim_leading(rest, "/")
    double_star(rest, key)
  end

  defp match(<<"*", rest::binary>>, key) do
    {chunk, key_rest} = next_chunk(key)
    _ = chunk
    rest = String.trim_leading(rest, "/")
    match(rest, String.trim_leading(key_rest, "/"))
  end

  defp match(<<c, prest::binary>>, <<c, krest::binary>>), do: match(prest, krest)
  defp match(_, _), do: false

  defp double_star(rest, key) do
    match(rest, key) or
      case String.split(key, "/", parts: 2) do
        [_] -> false
        [_, more] -> double_star(rest, more)
      end
  end

  defp next_chunk(key) do
    case String.split(key, "/", parts: 2) do
      [c] -> {c, ""}
      [c, r] -> {c, r}
    end
  end

  def hash64(bin) when is_binary(bin) do
    :erlang.phash2(bin, 0xFFFFFFFFFFFFFFFF)
  end
end
