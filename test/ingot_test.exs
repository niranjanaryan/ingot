defmodule IngotTest do
  use ExUnit.Case, async: false

  test "Zig NIF key_match and hash64" do
    assert Ingot.nif_loaded?()
    assert Ingot.key_match("ingot/cluster/**", "ingot/cluster/us/n1") == true
    assert Ingot.key_match("ingot/*/x", "ingot/a/x") == true
    assert Ingot.key_match("ingot/a", "ingot/b") == false
    assert is_integer(Ingot.hash64("hello"))
  end

  test "backends map" do
    b = Ingot.backends()
    assert is_boolean(b[:zenoh])
    assert is_boolean(b[:iroh])
    refute b[:iroh]
  end

  test "cluster starts zenoh without opening a live session" do
    {:ok, pid} =
      Ingot.Cluster.start_link(
        name: Ingot.Cluster.ZenohTest,
        zenoh: [connect: "tcp/127.0.0.1:7447", live: false],
        iroh: false
      )

    assert Process.alive?(pid)
    assert {:error, :backend_not_loaded} = Ingot.Zenoh.put("ingot/x", "hi")
    Supervisor.stop(pid)
  end

  test "cluster starts iroh stub without iroh_beam" do
    {:ok, pid} =
      Ingot.Cluster.start_link(
        name: Ingot.Cluster.IrohTest,
        iroh: [alpns: ["ingot/1"]],
        zenoh: false
      )

    assert {:error, :backend_not_loaded} = Ingot.Iroh.endpoint()
    Supervisor.stop(pid)
  end
end
