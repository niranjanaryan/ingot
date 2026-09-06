defmodule Mix.Tasks.Ingot do
  @moduledoc "Ingot CLI. Same as the `ingot` escript."
  use Mix.Task
  @shortdoc "ingot backends|match|hash|put|nif"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    Ingot.CLI.main(args, halt: false)
  end
end
