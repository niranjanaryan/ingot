defmodule IngotTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      for name <- [IngotCluster.Iroh, IngotCluster.Zenoh] do
        if pid = Process.whereis(name) do
          try do
            GenServer.stop(pid, :normal, 500)
          catch
            :exit, _ -> :ok
          end
        end
      end
    end)

    :ok
  end

  test "Zig NIF key_match and hash64" do
    assert IngotCluster.nif_loaded?()
    assert IngotCluster.key_match("ingot_cluster/cluster/**", "ingot_cluster/cluster/us/n1") == true
    assert IngotCluster.key_match("ingot_cluster/a", "ingot_cluster/b") == false
    assert is_integer(IngotCluster.hash64("hello"))
    b3 = IngotCluster.blake3("hello")
    assert byte_size(b3) == 32
    assert IngotCluster.blake3("hello") == b3
    assert IngotCluster.blake3("hello") != IngotCluster.blake3("world")
    assert is_integer(IngotCluster.xxh3("hello"))
    assert IngotCluster.xxh3("hello") != IngotCluster.xxh3("world")
  end

  test "memory storage S5 CID and BLAKE3 verify" do
    data = "ingot blob"
    {:ok, cid} = IngotCluster.Storage.put(data)
    assert cid.algo == :blake3
    assert cid.hash == IngotCluster.blake3(data)
    assert {:ok, ^data} = IngotCluster.Storage.get(cid)
    encoded = IngotCluster.Storage.CID.encode(cid)
    assert {:ok, decoded} = IngotCluster.Storage.CID.decode(encoded)
    assert decoded.hash == cid.hash
  end

  test "cluster starts iroh and zenoh stubs" do
    {:ok, pid} =
      IngotCluster.start_link(
        name: IngotCluster.Cluster.Test,
        iroh: [alpns: ["ingot_cluster/1"]],
        zenoh: [connect: "tcp/127.0.0.1:7447", live: false]
      )

    assert Process.alive?(pid)
    assert {:error, :backend_not_loaded} = IngotCluster.Iroh.endpoint()
    assert {:error, :backend_not_loaded} = IngotCluster.Zenoh.put("ingot_cluster/x", "hi")
    Supervisor.stop(pid)
  end

  test "backends" do
    b = IngotCluster.backends()
    assert is_boolean(b.iroh)
    assert is_boolean(b.zenoh)
    assert b.zig_nif
  end

  test "libcluster Iroh and Zenoh strategies start" do
    {:ok, iroh} =
      IngotCluster.Strategy.Iroh.start_link(
        topology: :ingot_cluster_iroh,
        config: [interval: 60_000, nodes: []]
      )

    {:ok, zenoh} =
      IngotCluster.Strategy.Zenoh.start_link(
        topology: :ingot_cluster_zenoh,
        config: [interval: 60_000, live: false, nodes: []]
      )

    assert Process.alive?(iroh)
    assert Process.alive?(zenoh)
    GenServer.stop(iroh)
    GenServer.stop(zenoh)
  end

  test "provisioners besides Fly are listed" do
    s = IngotCluster.Provisioner.status()
    assert s.local == true
    assert Map.has_key?(s, :docker)
    assert Map.has_key?(s, :fly)
    assert Map.has_key?(s, :k8s)
    assert Map.has_key?(s, :ec2)
    assert is_boolean(s.k8s)
    assert is_boolean(s.ec2)
    refute IngotCluster.Provisioner.available?(:ec2)
  end

  test "k8s provisioner needs FLAME terminator_sup" do
    {:ok, state} = IngotCluster.FLAME.Backend.init(provisioner: :k8s, overlay: :zenoh, live: false)
    assert {:error, {:provisioner_not_ready, :k8s}} = IngotCluster.FLAME.Backend.remote_boot(state)
  end

  test "CLI install paths" do
    assert is_binary(IngotCluster.CLI.Paths.bin_dir())
  end

  test "CLI help and backends" do
    assert :ok = IngotCluster.CLI.main(["--help"], halt: false)
    assert :ok = IngotCluster.CLI.main(["version"], halt: false)
    assert :ok = IngotCluster.CLI.main(["backends"], halt: false)
    assert :ok = IngotCluster.CLI.main(["match", "a/**", "a/b"], halt: false)
  end

  test "FLAME backend boots and runs a function" do
    {:ok, state} = IngotCluster.FLAME.Backend.init(provisioner: :local, overlay: :both, live: false)
    {:ok, _term, state} = IngotCluster.FLAME.Backend.remote_boot(state)
    parent = self()

    assert {:ok, {pid, ref}} =
             IngotCluster.FLAME.Backend.remote_spawn_monitor(state, fn ->
               send(parent, :ran)
               :ok
             end)

    assert is_pid(pid)
    assert is_reference(ref)
    assert_receive :ran, 1_000
  end
end
