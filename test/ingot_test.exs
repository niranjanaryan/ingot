defmodule IngotTest do
  use ExUnit.Case, async: false

  test "Zig NIF key_match and hash64" do
    assert Ingot.nif_loaded?()
    assert Ingot.key_match("ingot/cluster/**", "ingot/cluster/us/n1") == true
    assert Ingot.key_match("ingot/a", "ingot/b") == false
    assert is_integer(Ingot.hash64("hello"))
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
end
