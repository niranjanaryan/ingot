defmodule Ingot.FLAME.Backend do
  @moduledoc """
  Phoenix **FLAME** backend with Iroh and/or Zenoh membership overlay.

  Runners still execute via `:rpc` / `FLAME.LocalBackend` when the runner
  is local. The overlay publishes `{node, pid}` so a pool can find remote
  FLAME runners without Kubernetes DNS.

      config :flame, :backend, {Ingot.FLAME.Backend,
        provisioner: :local,  # :docker | :fly | :k8s | :ec2
        overlay: :iroh,
        alpns: ["ingot/flame"],
        connect: "tcp/127.0.0.1:7447",
        key: "ingot/flame/runners"
      }

  Implements the `FLAME.Backend` callback names (`init`, `remote_boot`,
  `remote_spawn_monitor`, `system_shutdown`, `handle_info`) when `flame`
  is a dependency of the host app.

  This is a **local runner** plus optional overlay advertise. It is not
  elastic FLAME (no terminator, no `FLAME_PARENT`, no remote node boot).
  See `zeiroh/EVAL.md`.
  """



  def init(opts) when is_list(opts) do
    overlay = Keyword.get(opts, :overlay, :both)
    provisioner = Ingot.Provisioner.normalize(opts)
    _ = start_overlay(overlay, opts)

    inner =
      case provisioner_init(provisioner, opts) do
        {:ok, inner} -> inner
        {:error, _} -> nil
        :skip -> nil
      end

    state = %{
      overlay: overlay,
      provisioner: provisioner,
      opts: opts,
      inner: inner,
      runner: nil,
      node: Node.self()
    }

    :telemetry.execute([:ingot, :flame, :init], %{system_time: System.system_time()}, %{
      overlay: overlay,
      provisioner: provisioner
    })

    {:ok, state}
  end

  def remote_boot(state) do
    mod = Ingot.Provisioner.backend_module(state.provisioner)

    case mod.boot(state) do
      {:ok, runner, state} ->
        advertise(state, Map.get(state, :node, Node.self()), runner)
        {:ok, runner, state}

      other ->
        other
    end
  end

  def remote_spawn_monitor(state, func) do
    mod = Ingot.Provisioner.backend_module(state.provisioner)

    case Map.get(state, :runner) do
      nil ->
        with {:ok, _term, state2} <- remote_boot(state) do
          mod.spawn_monitor(state2, func)
        end

      _ ->
        mod.spawn_monitor(state, func)
    end
  end

  def system_shutdown do
    Ingot.Provisioner.Local.shutdown()
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp provisioner_init(:local, _opts), do: :skip
  defp provisioner_init(:docker, _opts), do: :skip

  defp provisioner_init(name, opts) when name in [:fly, :k8s, :ec2] do
    if Keyword.has_key?(opts, :terminator_sup) do
      case name do
        :fly -> Ingot.Provisioner.Fly.init_inner(opts)
        :k8s -> Ingot.Provisioner.K8s.init_inner(opts)
        :ec2 -> Ingot.Provisioner.EC2.init_inner(opts)
      end
    else
      :skip
    end
  end

  defp provisioner_init(_, _), do: :skip

  defp start_overlay(:iroh, opts) do
    start_iroh(opts)
  end

  defp start_overlay(:zenoh, opts) do
    start_zenoh(opts)
  end

  defp start_overlay(:both, opts) do
    start_iroh(opts)
    start_zenoh(opts)
  end

  defp start_overlay(_, opts) do
    start_overlay(:both, opts)
  end

  defp start_iroh(opts) do
    unless Process.whereis(Ingot.Iroh) do
      Ingot.Iroh.start_link(alpns: Keyword.get(opts, :alpns, ["ingot/flame"]))
    end
  rescue
    _ -> :ok
  end

  defp start_zenoh(opts) do
    unless Process.whereis(Ingot.Zenoh) do
      Ingot.Zenoh.start_link(
        connect: Keyword.get(opts, :connect, "tcp/127.0.0.1:7447"),
        key: Keyword.get(opts, :key, "ingot/flame/runners"),
        live: Keyword.get(opts, :live, false)
      )
    end
  rescue
    _ -> :ok
  end

  defp advertise(%{overlay: overlay} = state, node, runner) do
    payload = "#{node} #{inspect(runner)}"

    if overlay in [:zenoh, :both] and Process.whereis(Ingot.Zenoh) do
      key = Keyword.get(state.opts, :key, "ingot/flame/runners")
      _ = Ingot.Zenoh.put(key, payload)
    end

    :ok
  rescue
    _ -> :ok
  end
end
