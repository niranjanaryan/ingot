defmodule Ingot.Provisioner.Fly do
  @moduledoc """
  Delegates boot to `FLAME.FlyBackend` when `flame` is in the host app.

      {Ingot.FLAME.Backend, provisioner: :fly, overlay: :iroh}
  """

  def boot(state) do
    if state[:inner] do
      delegate(:remote_boot, [inner(state)], state)
    else
      {:error, {:provisioner_not_ready, :fly}}
    end
  end

  def spawn_monitor(state, func), do: delegate(:remote_spawn_monitor, [inner(state), func], state)
  def shutdown, do: delegate(:system_shutdown, [], nil)

  def init_inner(opts) do
    if Code.ensure_loaded?(FLAME.FlyBackend) and function_exported?(FLAME.FlyBackend, :init, 1) do
      FLAME.FlyBackend.init(opts)
    else
      {:error, {:provisioner_not_loaded, :fly}}
    end
  end

  defp inner(%{inner: inner}) when not is_nil(inner), do: inner
  defp inner(state), do: state

  defp delegate(fun, args, state) do
    if Code.ensure_loaded?(FLAME.FlyBackend) and
         function_exported?(FLAME.FlyBackend, fun, length(args)) do
      wrap(apply(FLAME.FlyBackend, fun, args), state)
    else
      {:error, {:provisioner_not_loaded, :fly}}
    end
  end

  defp wrap({:ok, term, inner}, state), do: {:ok, term, Map.put(state, :inner, inner)}
  defp wrap({:ok, pair}, _state), do: {:ok, pair}
  defp wrap(:ok, _), do: :ok
  defp wrap(other, _), do: other
end
