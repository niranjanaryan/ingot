defmodule Mix.Tasks.Ingot.Build do
  @moduledoc false
  use Mix.Task

  @shortdoc "Builds the Ingot Zig NIF"
  @recursive true

  @impl Mix.Task
  def run(_args) do
    app_path = Mix.Project.app_path()
    priv_dir = Path.join(app_path, "priv")
    File.mkdir_p!(priv_dir)
    so_path = Path.join(priv_dir, "ingot_nif.so")
    src = "native/zig/ingot_nif.zig"

    so_ok? = match?({:ok, %{size: s}} when s > 1024, File.stat(so_path))
    need = not so_ok? or (File.exists?(src) and newer?(src, so_path))

    if need do
      Mix.shell().info("Compiling Ingot Zig NIF...")
      erts = System.get_env("ERTS_INCLUDE_DIR") || find_erts_include()

      {out, exit} =
        System.cmd("make", ["all", "MIX_APP_PATH=#{app_path}", "ERTS_INCLUDE_DIR=#{erts}"],
          stderr_to_stdout: true
        )

      IO.write(out)
      if exit != 0, do: raise("Failed to compile Ingot Zig NIF")
    end
  end

  defp find_erts_include do
    bin = System.find_executable("erl") || raise "set ERTS_INCLUDE_DIR"
    walk(Path.dirname(bin), 8) || raise "set ERTS_INCLUDE_DIR"
  end

  defp walk(_d, 0), do: nil

  defp walk(dir, n) do
    parent = Path.dirname(dir)

    case Path.wildcard(Path.join(parent, "erts-*")) do
      [erts | _] -> Path.join(erts, "include")
      [] -> walk(parent, n - 1)
    end
  end

  defp newer?(a, b) do
    case {File.stat(a, time: :posix), File.stat(b, time: :posix)} do
      {{:ok, %{mtime: t1}}, {:ok, %{mtime: t2}}} -> t1 > t2
      _ -> true
    end
  end
end
