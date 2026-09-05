# Ingot

**Iroh** P2P QUIC for Elixir (iron / dial keys).

```
gale  — Phoenix HTTP/3
ingot — Iroh
dusk  — Zenoh + zenohd
```

```elixir
{:ingot, "~> 0.1"}
# {:iroh_beam, "~> 0.2"}  # host app only

{Ingot, alpns: ["ingot/1"]}
```

MIT. https://github.com/niranjanaryan/ingot
