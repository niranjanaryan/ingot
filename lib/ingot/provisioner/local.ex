defmodule Ingot.Provisioner.Local do
  @moduledoc """
  In-process runner (same idea as `FLAME.LocalBackend`). Default when no cloud.
  """

  def boot(state) do
    parent = self()

    {:ok, pid} =
      Task.start_link(fn ->
        Process.flag(:trap_exit, true)

        receive do
          {:boot, caller} ->
            send(caller, {:booted, self(), Node.self()})
            loop(parent)
        end
      end)

    send(pid, {:boot, self()})

    receive do
      {:booted, runner, node} ->
        {:ok, runner, %{state | runner: runner, node: node}}
    after
      5_000 -> {:error, :boot_timeout}
    end
  end

  def spawn_monitor(%{runner: runner}, func)
      when is_pid(runner) and is_function(func, 0) do
    req = make_ref()
    send(runner, {:spawn, self(), req, func})

    receive do
      {:spawned, ^req, pid} ->
        {:ok, {pid, Process.monitor(pid)}}
    after
      5_000 -> {:error, :spawn_timeout}
    end
  end

  def spawn_monitor(_state, {mod, fun, args})
      when is_atom(mod) and is_atom(fun) and is_list(args) do
    {pid, ref} = Kernel.spawn_monitor(mod, fun, args)
    {:ok, {pid, ref}}
  end

  def shutdown, do: :ok

  defp loop(parent) do
    receive do
      {:spawn, from, ref, func} ->
        {pid, _} = Kernel.spawn_monitor(func)
        send(from, {:spawned, ref, pid})
        loop(parent)

      {:EXIT, ^parent, reason} ->
        exit(reason)

      _ ->
        loop(parent)
    end
  end
end
