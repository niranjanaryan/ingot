# IngotCluster Stacks Grant — Submission Checklist

**Portal:** https://portal.stacksendowment.co/apply/cycle-3  
**Deadline:** September 23, 2026  
**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations

---

## Form Fields

### Project Name
```
IngotCluster — Stacks Cluster Discovery and Storage
```

### Track
```
Getting Started Grant
```

### Theme
```
Distribution & Integrations
```

### Problem Statement
```
Stacks node deployment lacks native Elixir tooling for cluster discovery, content-addressed storage, and libcluster integration. Operators rely on static configs and external services for peer discovery, with no unified library for Iroh/Zenoh-based membership or S3/S5 artifact storage.
```

### Solution
```
IngotCluster provides Iroh DHT and Zenoh brokered pub/sub for Stacks node discovery, libcluster strategies for automatic peer membership, BLAKE3/XXH3 content addressing for block and transaction artifacts, and S3/S5 storage backends for relay state and indexer data. All from Elixir, tested on Hex.pm.
```

### What You Will Ship
```
Milestone 1 (Week 3): libcluster strategies for Stacks node membership via Iroh/Zenoh
Milestone 2 (Week 7): Content-addressed storage backend for block artifacts and relay logs
Milestone 3 (Week 10): FLAME backend for distributed Stacks indexers and monitors
```

### How This Helps Stacks
```
Provides Stacks operators with production-tested, Elixir-native cluster discovery and storage. Enables automatic peer membership, content-addressed block artifacts, and distributed off-chain workers for indexers and monitors without vendor lock-in.
```

### Budget
```
$6,500 STX — development (5,500 STX), cloud infrastructure for testing (500 STX), security review (250 STX), documentation (150 STX), buffer (100 STX)
```

### Team
```
Solo builder with 6+ open-source Elixir projects, including IngotCluster (Iroh + Zenoh cluster, libcluster strategies), Dusk (Zenoh-first cluster), Zeiroh (FLAME overlay), Gale (HTTP/3), and Orian (S3/S5 transfer). All MIT-licensed with CI and docs.
```

---

## Links

- GitHub: https://github.com/niranjanaryan/ingot_cluster
- Hex.pm: https://hex.pm/packages/ingot_cluster
- Proposal: https://github.com/niranjanaryan/ingot_cluster/blob/main/STACKS_GRANT.md

---

## Milestones

### Milestone 1
- **Title:** Stacks libcluster Strategies
- **Amount:** $2,000 STX
- **Duration:** Weeks 1–3
- **Deliverables:** `IngotCluster.Strategy.Iroh` and `IngotCluster.Strategy.Zenoh` with Stacks-specific configs, CLI: `ingot_cluster stacks peers`

### Milestone 2
- **Title:** Content-Addressed Storage for Stacks Artifacts
- **Amount:** $2,000 STX
- **Duration:** Weeks 4–7
- **Deliverables:** BLAKE3 CID for blocks/txs, `IngotCluster.Storage` S3/S5 backend for relay logs, integrity verification

### Milestone 3
- **Title:** FLAME Overlay for Distributed Stacks Services
- **Amount:** $2,500 STX
- **Duration:** Weeks 8–10
- **Deliverables:** `IngotCluster.FLAME.Backend` with Stacks overlay, distributed indexer example, relay monitor example, benchmarks

---

## Disbursement
```
50% at Milestone 1 (Week 3)
50% at Milestone 3 (Week 10)
```
