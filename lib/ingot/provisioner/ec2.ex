defmodule Ingot.Provisioner.EC2 do
  @moduledoc """
  Delegates boot to `FlameEC2` when that package is in the host app.

  Expects an S3 release bundle (`:s3_bundle_url`) per FlameEC2 docs.

      {Ingot.FLAME.Backend, provisioner: :ec2, overlay: :iroh}
  """

  @mod FlameEC2

  def boot(state) do
    if state[:inner] do
      delegate(:remote_boot, [inner(state)], state)
    else
      {:error, {:provisioner_not_ready, :ec2}}
    end
  end

  def spawn_monitor(state, func), do: delegate(:remote_spawn_monitor, [inner(state), func], state)
  def shutdown, do: delegate(:system_shutdown, [], nil)

  def init_inner(opts) do
    if Code.ensure_loaded?(@mod) and function_exported?(@mod, :init, 1) do
      apply(@mod, :init, [opts])
    else
      {:error, {:provisioner_not_loaded, :ec2}}
    end
  end

  defp inner(%{inner: inner}) when not is_nil(inner), do: inner
  defp inner(state), do: state

  defp delegate(fun, args, state) do
    if Code.ensure_loaded?(@mod) and function_exported?(@mod, fun, length(args)) do
      wrap(apply(@mod, fun, args), state)
    else
      {:error, {:provisioner_not_loaded, :ec2}}
    end
  end

  defp wrap({:ok, term, inner}, state), do: {:ok, term, Map.put(state, :inner, inner)}
  defp wrap({:ok, pair}, _state), do: {:ok, pair}
  defp wrap(:ok, _), do: :ok
  defp wrap(other, _), do: other
end
