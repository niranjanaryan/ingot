# Changelog

## 0.1.0 — 2026-09-06

* `Ingot.Cluster` supervisor: topologies `:zenoh` (brokered) and `:iroh` (P2P QUIC)
* Optional `zenohex` — Elixir nodes as Zenoh **clients** to `zenohd`
* Optional `iroh_beam` — dial Iroh endpoint IDs
* Optional `libcluster` strategy wrappers
* Zig NIF: Zenoh-style `key_match/2`, FNV-1a `hash64/1`
* Rust `ingot_key_bench` binary for codec comparison
* Does not replace Gale (Phoenix HTTP/3; Gale already uses a Zig NIF)
