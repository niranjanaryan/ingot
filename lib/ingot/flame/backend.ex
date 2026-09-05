defmodule Ingot.FLAME.Backend do
  @moduledoc """
  Phoenix **FLAME** backend with Iroh and/or Zenoh membership overlay.

  Runners still execute via `:rpc` / `FLAME.LocalBackend` when the runner
  is local. The overlay publishes `{node, pid}` so a pool can find remote
  FLAME runners without Kubernetes DNS.

      config :flame, :backend, {Ingot.FLAME.Backend,
        overlay: :iroh,
        # overlay: :zenoh,
        # overlay: :both,
        alpns: ["ingot/flame"],
        connect: "tcp/127.0.0.1:7447",
        key: "ingot/flame/runners"
      }

  Implements the `FLAME.Backend` callbacks (`init`, `remote_boot`,
  `remote_spawn_monitor`, `system_shutdown`, `handle_info`) when `flame`
  is a dependency of the host app.
  """



  def init(opts) when is_list(opts) do
    overlay = Keyword.get(opts, :overlay, :both)
    _ = start_overlay(overlay, opts)

    state = %{
      overlay: overlay,
      opts: opts,
      runner: nil,
      node: Node.self()
    }

    :telemetry.execute([:ingot, :flame, :init], %{system_time: System.system_time()}, %{
      overlay: overlay
    })

    {:ok, state}
  end

  def remote_boot(state) do
    parent = self()

    {:ok, pid} =
      Task.start_link(fn ->
        Process.flag(:trap_exit, true)

        receive do
          {:boot, caller} ->
            send(caller, {:booted, self(), Node.self()})
            runner_loop(parent)
        end
      end)

    send(pid, {:boot, self()})

    receive do
      {:booted, runner, node} ->
        advertise(state, node, runner)
        {:ok, remote_terminator_pid(runner), %{state | runner: runner, node: node}}
    after
      5_000 -> {:error, :boot_timeout}
    end
  end

  def remote_spawn_monitor(%{runner: runner} = _state, func)
      when is_pid(runner) and is_function(func, 0) do
    req = make_ref()
    send(runner, {:spawn, self(), req, func})

    receive do
      {:spawned, ^req, pid} ->
        {:ok, {pid, Process.monitor(pid)}}
    after
      5_000 ->
        {:error, :spawn_timeout}
    end
  end

  def remote_spawn_monitor(state, func) when is_function(func, 0) do
    with {:ok, _term, state2} <- remote_boot(state) do
      remote_spawn_monitor(state2, func)
    end
  end

  def system_shutdown do
    :ok
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp runner_loop(parent) do
    receive do
      {:spawn, from, ref, func} ->
        {pid, _} =
          spawn_monitor(fn ->
            func.()
          end)

        send(from, {:spawned, ref, pid})
        runner_loop(parent)

      {:EXIT, ^parent, reason} ->
        exit(reason)

      _ ->
        runner_loop(parent)
    end
  end

  defp remote_terminator_pid(runner), do: runner

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
