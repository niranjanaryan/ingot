defmodule IngotCluster.Cluster do
  @moduledoc """
  Supervisor for **Iroh** and/or **Zenoh**.

      {IngotCluster,
       iroh: [alpns: ["ingot_cluster/1"]],
       zenoh: [connect: "tcp/127.0.0.1:7447", key: "ingot_cluster/cluster/**"]}
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @impl true
  def init(opts) do
    iroh = Keyword.get(opts, :iroh, false)
    zenoh = Keyword.get(opts, :zenoh, false)

    children = iroh_child(iroh) ++ zenoh_child(zenoh)

    :telemetry.execute(
      [:ingot_cluster, :cluster, :init],
      %{system_time: System.system_time()},
      %{iroh: iroh != false, zenoh: zenoh != false}
    )

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp iroh_child(false), do: []
  defp iroh_child(true), do: [{IngotCluster.Iroh, []}]
  defp iroh_child(opts) when is_list(opts), do: [{IngotCluster.Iroh, opts}]

  defp zenoh_child(false), do: []
  defp zenoh_child(true), do: [{IngotCluster.Zenoh, [live: false]}]
  defp zenoh_child(opts) when is_list(opts), do: [{IngotCluster.Zenoh, opts}]
end
