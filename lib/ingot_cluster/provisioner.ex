defmodule IngotCluster.Provisioner do
  @moduledoc """
  Compute provisioners for FLAME. **Not Fly-only.**

  Iroh/Zenoh join nodes; these modules **create** the VM/container:

  | Atom | Module | Needs |
  |---|---|---|
  | `:local` | in-process Task | always |
  | `:docker` | Docker Engine CLI | `docker` on PATH, `:image` |
  | `:fly` | `FLAME.FlyBackend` | `{:flame, "~> 0.5"}`, `FLY_API_TOKEN` |
  | `:k8s` | `FLAMEK8sBackend` | `{:flame_k8s_backend, "~> 0.6"}` |
  | `:ec2` | `FlameEC2` | `{:flame_ec2, ...}`, S3 bundle |

      config :flame, :backend, {IngotCluster.FLAME.Backend,
        provisioner: :k8s,   # or :fly, :docker, :local, :ec2
        overlay: :iroh}

  See `zeiroh/SCALING.md`.
  """

  @known [:local, :docker, :fly, :k8s, :ec2, :hetzner, :crucible]

  def known, do: @known

  def normalize(opts) when is_list(opts) do
    case Keyword.get(opts, :provisioner, :local) do
      name when name in @known -> name
      mod when is_atom(mod) -> mod
      {name, _} when name in @known -> name
      other -> other
    end
  end

  def available?(:local), do: true

  def available?(:docker),
    do: is_binary(System.find_executable("docker"))

  def available?(:fly),
    do: Code.ensure_loaded?(FLAME.FlyBackend)

  def available?(:k8s),
    do: Code.ensure_loaded?(FLAMEK8sBackend)

  def available?(:ec2),
    do: Code.ensure_loaded?(FlameEC2)

  def available?(:hetzner), do: Code.ensure_loaded?(Crucible.Driver.Hetzner)
  def available?(:crucible), do: Code.ensure_loaded?(Crucible)

  def available?(mod) when is_atom(mod) do
    Code.ensure_loaded?(mod) or
      (Code.ensure_loaded?(Crucible) and Crucible.Providers.implemented?(mod))
  end

  def backend_module(:local), do: IngotCluster.Provisioner.Local
  def backend_module(:docker), do: IngotCluster.Provisioner.Docker
  def backend_module(:fly), do: IngotCluster.Provisioner.Fly
  def backend_module(:k8s), do: IngotCluster.Provisioner.K8s
  def backend_module(:ec2), do: IngotCluster.Provisioner.EC2

  def backend_module(name) when is_atom(name) do
    if Code.ensure_loaded?(Crucible) do
      Crucible.get_driver(name)
    else
      name
    end
  end

  def status do
    Map.new(@known, fn name -> {name, available?(name)} end)
  end
end
