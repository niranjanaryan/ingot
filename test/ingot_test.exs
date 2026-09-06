defmodule IngotTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      for name <- [Ingot.Iroh, Ingot.Zenoh] do
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
    assert Ingot.nif_loaded?()
    assert Ingot.key_match("ingot/cluster/**", "ingot/cluster/us/n1") == true
    assert Ingot.key_match("ingot/a", "ingot/b") == false
    assert is_integer(Ingot.hash64("hello"))
    b3 = Ingot.blake3("hello")
    assert byte_size(b3) == 32
    assert Ingot.blake3("hello") == b3
    assert Ingot.blake3("hello") != Ingot.blake3("world")
    assert is_integer(Ingot.xxh3("hello"))
    assert Ingot.xxh3("hello") != Ingot.xxh3("world")
  end

  test "memory storage S5 CID and BLAKE3 verify" do
    data = "ingot blob"
    {:ok, cid} = Ingot.Storage.put(data)
    assert cid.algo == :blake3
    assert cid.hash == Ingot.blake3(data)
    assert {:ok, ^data} = Ingot.Storage.get(cid)
    encoded = Ingot.Storage.CID.encode(cid)
    assert {:ok, decoded} = Ingot.Storage.CID.decode(encoded)
    assert decoded.hash == cid.hash
  end

  test "cluster starts iroh and zenoh stubs" do
    {:ok, pid} =
      Ingot.start_link(
        name: Ingot.Cluster.Test,
        iroh: [alpns: ["ingot/1"]],
        zenoh: [connect: "tcp/127.0.0.1:7447", live: false]
      )

    assert Process.alive?(pid)
    assert {:error, :backend_not_loaded} = Ingot.Iroh.endpoint()
    assert {:error, :backend_not_loaded} = Ingot.Zenoh.put("ingot/x", "hi")
    Supervisor.stop(pid)
  end

  test "backends" do
    b = Ingot.backends()
    assert is_boolean(b.iroh)
    assert is_boolean(b.zenoh)
    assert b.zig_nif
  end

  test "libcluster Iroh and Zenoh strategies start" do
    {:ok, iroh} =
      Ingot.Strategy.Iroh.start_link(
        topology: :ingot_iroh,
        config: [interval: 60_000, nodes: []]
      )

    {:ok, zenoh} =
      Ingot.Strategy.Zenoh.start_link(
        topology: :ingot_zenoh,
        config: [interval: 60_000, live: false, nodes: []]
      )

    assert Process.alive?(iroh)
    assert Process.alive?(zenoh)
    GenServer.stop(iroh)
    GenServer.stop(zenoh)
  end

  test "provisioners besides Fly are listed" do
    s = Ingot.Provisioner.status()
    assert s.local == true
    assert Map.has_key?(s, :docker)
    assert Map.has_key?(s, :fly)
    assert Map.has_key?(s, :k8s)
    assert Map.has_key?(s, :ec2)
    assert is_boolean(s.k8s)
    assert is_boolean(s.ec2)
    refute Ingot.Provisioner.available?(:ec2)
  end

  test "k8s provisioner needs FLAME terminator_sup" do
    {:ok, state} = Ingot.FLAME.Backend.init(provisioner: :k8s, overlay: :zenoh, live: false)
    assert {:error, {:provisioner_not_ready, :k8s}} = Ingot.FLAME.Backend.remote_boot(state)
  end

  test "CLI install paths" do
    assert is_binary(Ingot.CLI.Paths.bin_dir())
  end

  test "CLI help and backends" do
    assert :ok = Ingot.CLI.main(["--help"], halt: false)
    assert :ok = Ingot.CLI.main(["version"], halt: false)
    assert :ok = Ingot.CLI.main(["backends"], halt: false)
    assert :ok = Ingot.CLI.main(["match", "a/**", "a/b"], halt: false)
  end

  test "FLAME backend boots and runs a function" do
    {:ok, state} = Ingot.FLAME.Backend.init(provisioner: :local, overlay: :both, live: false)
    {:ok, _term, state} = Ingot.FLAME.Backend.remote_boot(state)
    parent = self()

    assert {:ok, {pid, ref}} =
             Ingot.FLAME.Backend.remote_spawn_monitor(state, fn ->
               send(parent, :ran)
               :ok
             end)

    assert is_pid(pid)
    assert is_reference(ref)
    assert_receive :ran, 1_000
  end
end
