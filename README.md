# Ingot

[![Hex.pm](https://img.shields.io/hexpm/v/ingot.svg)](https://hex.pm/packages/ingot)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

Elixir **cluster** over **Iroh** (P2P QUIC, iron/iroh) and **Zenoh** (brokered `zenohd`).

HTTP/3 for Phoenix is **[Gale](https://github.com/niranjanaryan/gale)**. Ingot is the node-to-node bus.

## Install

```elixir
def deps do
  [
    {:ingot, "~> 0.1"},
    {:zenohex, "~> 0.10"}
    # {:iroh_beam, "~> 0.2"}  # do not mix with zenohex 0.10 (rustler_precompiled clash)
  ]
end
```

```elixir
{Ingot.Cluster,
 zenoh: [connect: "tcp/127.0.0.1:7447", key: "ingot/cluster/**"],
 iroh: false}
```

Run a broker:

```bash
zenohd --listen tcp/0.0.0.0:7447
# or QUIC: --listen quic/0.0.0.0:7447
```

Elixir nodes are Zenoh **clients**. That is the MQTT-like **brokered** topology (works across NAT if `zenohd` is public). Mesh/peer mode is Zenoh itself; Ingot defaults to client→router.

## Iroh

Dial **endpoint IDs**, not IPs. `iroh_beam` handles hole punch + n0 relay. Ingot does not implement Erlang distribution; use `iroh_beam`’s `-proto_dist iroh` if you need that.

## vs Gale / libcluster

| | Gale | Ingot | libcluster |
|---|---|---|---|
| Job | Phoenix H1/H2/H3 | Iroh + Zenoh cluster | EPMD/DNS/k8s membership |
| Transport | QUIC HTTP/3 | Zenoh TCP/QUIC, Iroh QUIC | TCP dist |
| Broker | no | **zenohd** | no |

## FOSS

MIT. Canonical repo: [github.com/niranjanaryan/ingot](https://github.com/niranjanaryan/ingot). Sponsors: [niranjanaryan](https://github.com/sponsors/niranjanaryan).
