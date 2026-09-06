defmodule Mix.Tasks.Ingot.Install do
  @moduledoc "Build escript + NIFs and install `ingot` for Linux, macOS, and Windows."
  use Mix.Task
  @shortdoc "Install the ingot CLI (all OS)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("ingot.build")
    Mix.Task.run("compile")
    Mix.Task.run("escript.build")

    dest = Ingot.CLI.Paths.install_escript("ingot")
    priv = Ingot.CLI.Paths.copy_priv(:ingot)
    Mix.shell().info("installed #{dest}")
    Mix.shell().info("NIFs in #{priv}")
    Mix.shell().info(path_hint())
  end

  defp path_hint do
    dir = Ingot.CLI.Paths.bin_dir()

    if Ingot.CLI.Paths.windows?() do
      "add #{dir} to PATH (Windows: System Properties → Environment Variables)"
    else
      "ensure #{dir} is on PATH"
    end
  end
end
