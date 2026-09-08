defmodule IngotCluster.Provisioner.Docker do
  @moduledoc """
  Boot a runner with the Docker CLI (`docker run`). Laptop/CI provisioner.

      {IngotCluster.FLAME.Backend,
        provisioner: :docker,
        overlay: :zenoh,
        image: "myapp:latest"}

  Does not use Kind. Requires `docker` on PATH. Full `FLAME_PARENT` wire-up
  still needs the release to start `FLAME.Terminator` inside the container.
  """

  def boot(state) do
    opts = Map.get(state, :opts, [])
    image = Keyword.get(opts, :image) || System.get_env("FLAME_DOCKER_IMAGE")

    cond do
      not IngotCluster.Provisioner.available?(:docker) ->
        {:error, {:provisioner_not_loaded, :docker}}

      not is_binary(image) or image == "" ->
        {:error, :docker_image_required}

      true ->
        run(image, state)
    end
  end

  def spawn_monitor(state, func), do: IngotCluster.Provisioner.Local.spawn_monitor(state, func)

  def shutdown, do: :ok

  defp run(image, state) do
    overlay_env = overlay_env(state)

    args =
      ["run", "-d", "--rm"] ++
        Enum.flat_map(overlay_env, fn {k, v} -> ["-e", "#{k}=#{v}"] end) ++
        [image]

    case System.cmd("docker", args, stderr_to_stdout: true) do
      {id, 0} ->
        cid = String.trim(id)
        {:ok, self(), Map.put(state, :docker_id, cid)}

      {out, code} ->
        {:error, {:docker_run_failed, code, String.slice(out, 0, 500)}}
    end
  end

  defp overlay_env(state) do
    opts = Map.get(state, :opts, [])

    [
      {"ZENOH_CONNECT", Keyword.get(opts, :connect, "tcp/127.0.0.1:7447")},
      {"INGOT_OVERLAY", to_string(Map.get(state, :overlay, :both))}
    ]
  end
end
