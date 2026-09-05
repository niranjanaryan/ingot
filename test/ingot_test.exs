defmodule IngotTest do
  use ExUnit.Case, async: false

  test "Zig hash64 NIF" do
    assert Ingot.nif_loaded?()
    assert is_integer(Ingot.hash64("hello"))
  end

  test "Iroh stub without iroh_beam" do
    {:ok, pid} = Ingot.start_link(alpns: ["ingot/1"])
    assert {:error, :backend_not_loaded} = Ingot.Iroh.endpoint()
    GenServer.stop(pid)
  end
end
