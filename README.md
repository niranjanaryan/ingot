# Ingot

[![Hex.pm](https://img.shields.io/hexpm/v/ingot_cluster.svg)](https://hex.pm/packages/ingot_cluster)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/ingot_cluster)
[![CI](https://github.com/niranjanaryan/ingot/actions/workflows/ci.yml/badge.svg)](https://github.com/niranjanaryan/ingot/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

**Iroh** (iron, P2P QUIC) **and Zenoh** (brokered `zenohd`) in one Elixir cluster package.

```
gale   — Phoenix HTTP/3
ingot  — Iroh + Zenoh (Hex: `ingot_cluster`; `ingot` is taken)
dusk   — Zenoh + Iroh
orian  — BLAKE3 / S3 / S5 storage
zeiroh — Phoenix FLAME overlay
```

```elixir
{:ingot, "~> 0.1", hex: :ingot_cluster}

{Ingot,
 iroh: [alpns: ["ingot/1"]],
 zenoh: [connect: "tcp/127.0.0.1:7447", key: "ingot/cluster/**"]}
```

Add **one** of these in the host app (rustler pin clash if both):

```elixir
{:iroh_beam, "~> 0.2"}   # Iroh
{:zenohex, "~> 0.10"}    # Zenoh
```

Zig NIF: key-expr match, FNV `hash64`, **BLAKE3**, **XXH3**. See [HASH.md](HASH.md).

Fast path: **[orian](https://github.com/niranjanaryan/orian)**. Built-in:

```elixir
{:ok, cid} = Ingot.Storage.put(body)                    # memory, BLAKE3 CID
Ingot.Storage.put(body, backend: :s3, bucket: "b", unsigned: true, host: "127.0.0.1:9000", scheme: "http")
Ingot.Storage.put(body, backend: :s5, endpoint: "http://127.0.0.1:5050")
```

MIT. https://github.com/niranjanaryan/ingot

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
config :flame, :backend, {Ingot.FLAME.Backend,
  provisioner: :local,   # :docker | :fly | :k8s | :ec2
  overlay: :both,
  live: false}
```

`provisioner` is **not Fly-only**: local, Docker CLI, `FLAME.FlyBackend`,
`FLAMEK8sBackend`, `FlameEC2`. Host app adds the matching Hex package.
`overlay:` `:iroh`, `:zenoh`, or `:both`. Optional `{:flame, "~> 0.5"}`.

**Limits:** this boots a **local** runner Task and may advertise `{node, pid}`
on Zenoh. It does not start `FLAME.Terminator`, set `FLAME_PARENT`, or
provision a remote BEAM node. Iroh/Zenoh cannot replace Fly/K8s boot; they
can only discover existing nodes. Full eval: [EVAL.md](https://github.com/niranjanaryan/zeiroh/blob/main/EVAL.md). Scaling (provision + overlay):
[SCALING.md](https://github.com/niranjanaryan/zeiroh/blob/main/SCALING.md).

libcluster strategies currently connect a **static** `config[:nodes]` list;
they do not yet subscribe to live Iroh/Zenoh membership.
