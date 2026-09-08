defmodule Mix.Tasks.IngotCluster do
  @moduledoc "IngotCluster CLI. Same as the `ingot_cluster` escript."
  use Mix.Task
  @shortdoc "ingot backends|match|hash|put|nif"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    IngotCluster.CLI.main(args, halt: false)
  end
end
