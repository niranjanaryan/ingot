# Changelog

## 0.1.0 — 2026-09-06

First public Hex release. Package name on Hex.pm is **`ingot_cluster`**.
OTP app is `:ingot_cluster`.

* Iroh + Zenoh cluster supervisor
* libcluster: `IngotCluster.Strategy.Iroh`, `IngotCluster.Strategy.Zenoh`
* Phoenix FLAME: `IngotCluster.FLAME.Backend` and provisioners (`:local`, `:docker`, `:fly`, `:k8s`, `:ec2`)
* Zig dirty-CPU NIF: key_match, BLAKE3, XXH3
* S3/S5 storage; defers to Orian when loaded
* `ingot_cluster` CLI (`mix ingot_cluster.binary` Burrito single file; else escript)
