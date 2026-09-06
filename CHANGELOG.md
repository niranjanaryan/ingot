# Changelog

## 0.1.0 — 2026-09-06

First public Hex release.

* Iroh + Zenoh cluster supervisor
* libcluster: `Ingot.Strategy.Iroh`, `Ingot.Strategy.Zenoh`
* Phoenix FLAME: `Ingot.FLAME.Backend` and provisioners (`:local`, `:docker`, `:fly`, `:k8s`, `:ec2`)
* Zig dirty-CPU NIF: key_match, BLAKE3, XXH3
* S3/S5 storage; defers to Orian when loaded
