# Stacks Endowment Grant Application — IngotCluster Stacks Node Coordination

**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations (Q3 2026)  
**Request:** $5,500 STX  
**Timeline:** 10 weeks  

---

## 1. Project Summary

**IngotCluster** is an Iroh + Zenoh cluster for Elixir with libcluster strategies and a FLAME backend. We are requesting a Getting Started Grant to add a **Stacks-specific coordination layer** that enables distributed Stacks node discovery, cluster membership, and off-chain service orchestration — all from Elixir.

Today, Stacks node operators and sBTC relay operators rely on centralized APIs, static peer lists, or manual networking configuration. There is no language-native, FLAME-compatible coordination layer that treats Stacks infrastructure as a first-class citizen. IngotCluster fills this gap by providing Iroh DHT-backed node discovery and Zenoh pub/sub for distributed coordination that can run alongside existing Stacks tooling.

**Why Stacks:** As PoX-5, sBTC, and the Nakamoto upgrade scale, Stacks operators need resilient, low-latency node coordination that doesn't depend on a single relay or static config. IngotCluster gives them a self-healing cluster data plane written in Elixir, composable with any Stacks backend.

---

## 2. Problem Statement

Stacks infrastructure coordination is centralized and fragile:

- **Static peer lists**: Node operators manually configure `peers` in `stacks-node.toml`. If a peer goes down, discovery halts.
- **Centralized RPC**: dApps and relays hit a single API endpoint. No built-in replication or failover.
- **No cluster membership**: Block propagation, transaction gossip, and sBTC relay coordination rely on TCP gossip protocols that are hard to operate behind NAT or in multi-region setups.
- **Off-chain services**: Stacks dApps that need distributed workers (indexers, relay monitors, fraud detectors) have no standard FLAME-compatible coordination layer.

**The gap:** No Elixir-native cluster coordination layer designed for Stacks node and relay communication. Existing options are generic libp2p wrappers or single-language tools that don't integrate with Phoenix/FLAME.

---

## 3. Solution

IngotCluster adds a `IngotCluster.Stacks` backend that provides:

1. **Cluster node discovery** — Iroh-based DHT for Stacks signer and API node discovery. Nodes advertise their IP, port, and version without a central tracker.
2. **FLAME overlay for Stacks services** — Use IngotCluster's existing FLAME backend to spawn distributed off-chain workers (indexers, relay monitors, fraud watchers) that auto-discover each other via Iroh/Zenoh.
3. **sBTC relay coordination** — Zenoh pub/sub for relay-to-relay Bitcoin/Stacks state synchronization, replacing or complementing centralized message queues.

```elixir
# Stacks node with P2P discovery
{IngotCluster, overlay: :stacks, backend: :iroh,
  iroh: [alpns: ["stacks/node/1", "stacks/relay/1"]]}

# FLAME worker for Stacks indexer
{FLAME.Pool,
  name: StacksIndexer,
  backend: {IngotCluster.FLAME.Backend,
    overlay: :stacks,
    provisioner: {Crucible, driver: :hetzner}}}

# sBTC relay pub/sub
{:ok, session} = IngotCluster.Zenoh.session("stacks/sbtc/relay/**")
IngotCluster.Zenoh.publish(session, "stacks/sbtc/relay/status", %{height: 12345})
```

CLI parity:

```bash
ingot stacks peers          # discover Stacks nodes via Iroh DHT
ingot stacks relay-status   # subscribe to sBTC relay status via Zenoh
ingot flame --overlay stacks # spawn FLAME workers with Stacks overlay
```

**Design choices:**
- Backward-compatible: existing IngotCluster users unaffected; Stacks overlay is opt-in via `overlay: :stacks`.
- Interoperable: Iroh and Zenoh both speak QUIC, so Stacks nodes can communicate across firewalls.
- Composable: works with Crucible for provisioning, Gale for HTTP transport, and existing Stacks node binaries.

---

## 4. Why This Matters for Stacks

**Ecosystem impact:**
- Eliminates single-point-of-failure peer discovery for Stacks node operators.
- Enables geo-redundant sBTC relay networks without centralized message brokers.
- Gives Stacks dApp developers a standard way to run distributed off-chain workers (indexers, monitors) using Phoenix FLAME + Elixir.

**Strategic alignment:**
- Directly supports the Nakamoto-upgraded network by improving node resilience and discovery.
- Enables sBTC utility by providing a peer-to-peer relay coordination layer.
- Fits the Q3 2026 "Distribution & Integrations" theme: infrastructure that connects Stacks nodes, relays, and dApps in a distributed, fault-tolerant way.

**Ecosystem-first:**
- Open-source (MIT), no token, no platform fee.
- Other Stacks projects can adopt the P2P overlay independently.
- Works with any Stacks node implementation that supports standard TCP/QUIC networking.

---

## 5. Milestones

### Milestone 1: Stacks Node Discovery via Iroh DHT (Weeks 1–3, $1,500 STX)

**Deliverable:** Working `IngotCluster.Stacks` node discovery backend.

- Iroh DHT namespace for Stacks nodes (`stacks/node/1` ALPN).
- `ingot stacks peers` CLI: discover, list, and ping Stacks nodes.
- Node identity: each node gets a stable Iroh peer ID derived from its Stacks `stx.address`.
- Integration with `stacks-node` config: auto-generate `p2p.bootnodes` from DHT peers.
- Tests: mock Iroh DHT, contract tests for discovery protocol.

**Verification:** Published v0.2.0 with docs and a demo showing two Stacks nodes discovering each other via Iroh without manual config.

### Milestone 2: FLAME Overlay for Stacks Off-Chain Services (Weeks 4–7, $2,000 STX)

**Deliverable:** FLAME backend for distributed Stacks indexers and relay monitors.

- `IngotCluster.FLAME.Backend` with Stacks-specific overlay config.
- Auto-discovery of FLAME workers via Iroh/Zenoh.
- Example: distributed Stacks block indexer that shards by burnchain block range.
- Example: sBTC relay health monitor that aggregates status from multiple relays.
- Integration with Crucible for provisioning workers across clouds.

**Verification:** Published v0.3.0 with a tutorial: "Running a Distributed Stacks Indexer with IngotCluster + Crucible".

### Milestone 3: sBTC Relay Pub/Sub + Production Packaging (Weeks 8–10, $2,000 STX)

**Deliverable:** Zenoh-based relay coordination and Burrito binary packaging.

- Zenoh pub/sub for sBTC relay state (`stacks/sbtc/relay/**`).
- Relay status aggregation and conflict detection.
- Burrito single-binary build for standalone CLI.
- Performance benchmarks: discovery latency, message throughput, failover time.
- Security review of peer identity and message authentication.

**Verification:** Published v0.4.0, demo at Stacks community event, and open issues for relay operator feedback.

---

## 6. Budget

| Item | Amount (STX) | Notes |
|------|-------------|-------|
| Development (3 milestones) | 4,800 | 10 weeks at ~480 STX/week |
| Cloud infrastructure for testing | 400 | Hetzner/DO nodes for live P2P tests |
| Security review | 200 | Peer identity, message auth |
| Documentation & demo production | 100 | Tutorials, screencasts |
| Buffer | 100 | Contingency |
| **Total** | **5,500** | Mid-range of Getting Started Grant |

**Disbursement:** 50% at Milestone 1 (Week 3), 50% at Milestone 3 (Week 10).

---

## 7. Team

**Niranjan Aryan** — solo builder, [@niranjanaryan](https://github.com/niranjanaryan).

- **Relevant experience:** Maintains IngotCluster (Iroh + Zenoh cluster, libcluster strategies, FLAME backend), Dusk (Zenoh-first cluster), Crucible (multi-cloud provisioner), Gale (HTTP/3), and Orian (S3/S5 transfer). All published on Hex.pm with CI, docs, and community funding.
- **GitHub:** [github.com/niranjanaryan](https://github.com/niranjanaryan)
- **Stacks engagement:** First application. Building coordination infrastructure that makes Stacks node and relay networking resilient and distributed.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Iroh/Zenoh protocol changes | Low | Medium | Pin to stable releases; abstract protocol layer |
| Stacks node config incompatibility | Medium | Medium | Support `stacks-node` v2.x+; document version pinning |
| NAT traversal issues for P2P | Medium | Medium | Use Iroh's hole-punching; fallback to Zenoh brokered mode |
| Scope creep (too many Stacks features) | Medium | Medium | Milestone 1 is discovery only; Milestone 2 adds FLAME; Milestone 3 adds relay |
| Solo builder bandwidth | Medium | Low | 10 weeks, focused scope; existing IngotCluster codebase reduces risk |

---

## 9. Ecosystem Commitment

- **Long-term maintenance:** IngotCluster is part of a maintained Elixir infrastructure toolkit. Stacks overlay will receive ongoing updates.
- **Community:** Open to Stacks ecosystem contributions; will label `good first issue` for Stacks-specific work.
- **Stacks alignment:** Driver will evolve with Stacks releases (Nakamoto, PoX-5, sBTC). No exit strategy.

---

## 10. Proof of Work

- **IngotCluster:** Published on Hex.pm, Iroh + Zenoh cluster with DHT and pub/sub, CI, docs.
- **Dusk:** Zenoh-first cluster with BLAKE3/S5/S3 storage.
- **Crucible:** Multi-cloud provisioner with 100+ provider catalog.
- **GitHub:** Active maintainer of 6+ open-source Elixir repos.

---

## 11. Application Answers (Form-Field Ready)

**Project name:** IngotCluster — Stacks Node Coordination

**Track:** Getting Started Grant

**Theme:** Distribution & Integrations

**Problem:** Stacks node and sBTC relay networking relies on static configs and centralized relays, creating single points of failure.

**Solution:** A coordination backend for IngotCluster that gives Stacks nodes and relays Iroh/Zenoh-based discovery, FLAME-compatible off-chain workers, and pub/sub relay coordination.

**What you will ship and by when:**
- Week 3: Iroh DHT-based Stacks node discovery
- Week 7: FLAME overlay for distributed Stacks indexers/monitors
- Week 10: Zenoh pub/sub for sBTC relay coordination

**How this helps Stacks:** Makes Stacks node and relay networking resilient, distributed, and fault-tolerant without centralized infrastructure.

**Budget:** $5,500 STX — development, testing, security review, documentation.

**Team:** Solo builder with 6+ open-source Elixir projects, including IngotCluster (Iroh + Zenoh cluster), Dusk, and Crucible.
