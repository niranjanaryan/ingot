defmodule Ingot.CLI do
  @moduledoc "Standalone CLI (`ingot`) and Mix task (`mix ingot`)."

  @version Mix.Project.config()[:version]

  @help """
  ingot #{@version} — Iroh + Zenoh cluster

    ingot backends
    ingot match PAT KEY
    ingot hash FILE [--algo blake3|xxh3|hash64]
    ingot put  FILE
    ingot nif
    ingot version

  Install: mix ingot.install
    Linux/macOS: ~/.local/bin
    Windows:     %LOCALAPPDATA%\\elixcoder\\bin
    Override:    ELIXCODER_BIN
  Hex: {:ingot, "~> 0.1", hex: :ingot_cluster}
  """

  def main(args), do: main(args, halt: !mix?())

  def main(args, opts) do
    _ = Application.ensure_all_started(:ingot)

    {parsed, rest, _} =
      OptionParser.parse(args,
        strict: [algo: :string, help: :boolean, version: :boolean],
        aliases: [h: :help, v: :version]
      )

    result =
      cond do
        parsed[:help] == true ->
          info(@help)
          :ok

        parsed[:version] == true or rest == ["version"] ->
          info("ingot #{@version}")
          :ok

        rest == [] ->
          info(@help)
          :ok

        true ->
          dispatch(rest, parsed)
      end

    finish(result, Keyword.get(opts, :halt, false))
  end

  defp dispatch(["backends" | _], _), do: info(inspect(Ingot.backends(), pretty: true))

  defp dispatch(["match", pat, key | _], _) do
    info(inspect(Ingot.key_match(pat, key)))
    :ok
  end

  defp dispatch(["hash", file | _], parsed) do
    bin = File.read!(file)

    case parsed[:algo] || "blake3" do
      "blake3" ->
        info(Base.encode16(Ingot.blake3(bin), case: :lower))
        :ok

      "xxh3" ->
        info(Integer.to_string(Ingot.xxh3(bin)))
        :ok

      "hash64" ->
        info(Integer.to_string(Ingot.hash64(bin)))
        :ok

      other ->
        err("unknown algo #{other}")
        {:error, :algo}
    end
  end

  defp dispatch(["put", file | _], _) do
    {:ok, cid} = Ingot.Storage.put(File.read!(file))
    info(Ingot.Storage.CID.hex(cid))
    :ok
  end

  defp dispatch(["nif" | _], _) do
    info("nif=#{Ingot.nif_loaded?()}")
    :ok
  end

  defp dispatch(_, _) do
    info(@help)
    :ok
  end

  defp info(msg), do: IO.puts(msg)
  defp err(msg), do: IO.puts(:stderr, msg)

  defp mix? do
    Code.ensure_loaded?(Mix.Project) and function_exported?(Mix.Project, :get, 0)
  rescue
    _ -> false
  end

  defp finish(:ok, false), do: :ok
  defp finish({:error, _} = e, false), do: e
  defp finish(:ok, true), do: System.halt(0)
  defp finish(_, true), do: System.halt(1)
end
