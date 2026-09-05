defmodule Mix.Tasks.Ingot.Build do
  @moduledoc false
  use Mix.Task
  @shortdoc "Builds the Ingot Zig NIF"
  @recursive true

  @impl Mix.Task
  def run(_args) do
    app_path = Mix.Project.app_path()
    File.mkdir_p!(Path.join(app_path, "priv"))
    so = Path.join(app_path, "priv/ingot_nif.so")
    src = "native/zig/ingot_nif.zig"
    ok = match?({:ok, %{size: s}} when s > 1024, File.stat(so))
    need = not ok or (File.exists?(src) and newer?(src, so))

    if need do
      Mix.shell().info("Compiling Ingot Zig NIF...")
      erts = System.get_env("ERTS_INCLUDE_DIR") || find_erts()

      {out, e} =
        System.cmd("make", ["all", "MIX_APP_PATH=#{app_path}", "ERTS_INCLUDE_DIR=#{erts}"],
          stderr_to_stdout: true
        )

      IO.write(out)
      if e != 0, do: raise("Ingot NIF compile failed")
    end
  end

  defp find_erts do
    bin = System.find_executable("erl") || raise "ERTS_INCLUDE_DIR"
    walk(Path.dirname(bin), 8) || raise "ERTS_INCLUDE_DIR"
  end

  defp walk(_, 0), do: nil

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
