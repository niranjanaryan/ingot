# Ingot

**Iroh** (iron, P2P QUIC) **and Zenoh** (brokered `zenohd`) in one Elixir cluster package.

```
gale  — Phoenix HTTP/3
ingot — Iroh + Zenoh
dusk  — Zenoh-only
```

```elixir
{:ingot, "~> 0.1"}

{Ingot,
 iroh: [alpns: ["ingot/1"]],
 zenoh: [connect: "tcp/127.0.0.1:7447", key: "ingot/cluster/**"]}
```

Add **one** of these in the host app (rustler pin clash if both):

```elixir
{:iroh_beam, "~> 0.2"}   # Iroh
{:zenohex, "~> 0.10"}    # Zenoh
```

Zig NIF for key-expr match + hash. MIT. https://github.com/niranjanaryan/ingot

## libcluster

```elixir
config :libcluster,
  topologies: [
    iron: [strategy: Ingot.Strategy.Iroh, config: [alpns: ["ingot/1"]]],
    zenoh: [
      strategy: Ingot.Strategy.Zenoh,
      config: [connect: "tcp/127.0.0.1:7447", key: "ingot/cluster/nodes"]
    ]
  ]
```

Optional `{:libcluster, "~> 3.5"}` in the host app.

## Phoenix FLAME

```elixir
config :flame, :backend, {Ingot.FLAME.Backend, overlay: :both, live: false}
```

`overlay:` `:iroh`, `:zenoh`, or `:both`. Optional `{:flame, "~> 0.5"}`.
