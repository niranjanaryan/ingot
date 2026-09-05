defmodule Ingot.Provisioner.K8s do
  @moduledoc """
  Delegates boot to `FLAMEK8sBackend` (`{:flame_k8s_backend, "~> 0.6"}`).

  Needs `POD_NAME` and `POD_NAMESPACE` on the parent pod. Overlay env
  (`ZENOH_CONNECT`, Iroh ticket) should be set on the runner manifest.

      {Ingot.FLAME.Backend, provisioner: :k8s, overlay: :zenoh}
  """

  @mod FLAMEK8sBackend

  def boot(state) do
    if state[:inner] do
      delegate(:remote_boot, [inner(state)], state)
    else
      {:error, {:provisioner_not_ready, :k8s}}
    end
  end
  def spawn_monitor(state, func), do: delegate(:remote_spawn_monitor, [inner(state), func], state)
  def shutdown, do: delegate(:system_shutdown, [], nil)

  def init_inner(opts) do
    if Code.ensure_loaded?(@mod) and function_exported?(@mod, :init, 1) do
      apply(@mod, :init, [opts])
    else
      {:error, {:provisioner_not_loaded, :k8s}}
    end
  end

  defp inner(%{inner: inner}) when not is_nil(inner), do: inner
  defp inner(state), do: state

  defp delegate(fun, args, state) do
    if Code.ensure_loaded?(@mod) and function_exported?(@mod, fun, length(args)) do
      wrap(apply(@mod, fun, args), state)
    else
      {:error, {:provisioner_not_loaded, :k8s}}
    end
  end

  defp wrap({:ok, term, inner}, state), do: {:ok, term, Map.put(state, :inner, inner)}
  defp wrap({:ok, pair}, _state), do: {:ok, pair}
  defp wrap(:ok, _), do: :ok
  defp wrap(other, _), do: other
end
