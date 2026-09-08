# Elixir Forum Announcement — IngotCluster 0.1.0

Post this to [Elixir Forum](https://elixirforum.com/) under **Announcements** or **Libraries and Tools**.

---

**Title:** `[ANN] IngotCluster 0.1.0 — Iroh + Zenoh cluster for Elixir, BLAKE3/S5/S3 storage`

**Body:**

Hi everyone,

I’m happy to announce the first public release of **IngotCluster** — an Iroh + Zenoh cluster library for Elixir with BLAKE3 hashing, S3/S5 storage, and a CLI.

**Why IngotCluster?**
- **Dual cluster**: Iroh (P2P QUIC) and Zenoh (brokered `zenohd`) in one package.
- **libcluster strategies**: `IngotCluster.Strategy.Iroh` and `IngotCluster.Strategy.Zenoh` for plug-and-play node discovery.
- **Storage**: `:memory`, `:s3`, `:s5` — defers to [Orian](https://github.com/niranjanaryan/orian) when loaded.
- **Hashing**: Zig dirty-CPU NIF for BLAKE3 and XXH3.
- **CLI**: `mix ingot_cluster.install` drops a Burrito single binary (or escript). Example:
  ```bash
  ingot_cluster backends
  ingot_cluster match "a/**" a/b
  ingot_cluster hash ./file --algo blake3
  ingot_cluster put ./file
  ```
- **Phoenix FLAME**: `IngotCluster.FLAME.Backend` with local/docker/fly/k8s/ec2 provisioners.

**Install**
```elixir
defp deps do
  [
    {:ingot_cluster, "~> 0.1", hex: :ingot_cluster},
    {:iroh_beam, "~> 0.2"}   # or {:zenohex, "~> 0.10"}
  ]
end
```

**Docs & Source**
- [Hex.pm](https://hex.pm/packages/ingot_cluster)
- [Hexdocs](https://hexdocs.pm/ingot_cluster)
- [GitHub](https://github.com/niranjanaryan/ingot_cluster)

**Sponsor / Funding**
If this is useful to you, I would appreciate GitHub Sponsors to keep the NIFs and cluster stack maintained:
- [github.com/sponsors/niranjanaryan](https://github.com/sponsors/niranjanaryan)

Feedback, issues, and PRs welcome.

— Niranjan

---

## Related Packages

- [Dusk](https://github.com/niranjanaryan/dusk) — Zenoh-first cluster
- [Zeiroh](https://github.com/niranjanaryan/zeiroh) — Phoenix FLAME overlay
- [Gale](https://github.com/niranjanaryan/gale) — HTTP/3
- [Orian](https://github.com/niranjanaryan/orian) — BLAKE3 / S3 / S5 storage
