defmodule Ingot.Cluster do
  @moduledoc """
  Supervisor for Zenoh-brokered and/or Iroh P2P cluster transports.

      children = [
        {Ingot.Cluster,
         zenoh: [connect: "tcp/127.0.0.1:7447"],
         iroh: false}
      ]
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
    zenoh = Keyword.get(opts, :zenoh, false)
    iroh = Keyword.get(opts, :iroh, false)

    children =
      zenoh_child(zenoh) ++ iroh_child(iroh)

    :telemetry.execute(
      [:ingot, :cluster, :init],
      %{system_time: System.system_time()},
      %{zenoh: zenoh != false, iroh: iroh != false}
    )

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp zenoh_child(false), do: []
  defp zenoh_child(opts) when is_list(opts), do: [{Ingot.Zenoh, opts}]

  defp iroh_child(false), do: []
  defp iroh_child(opts) when is_list(opts), do: [{Ingot.Iroh, opts}]
end
