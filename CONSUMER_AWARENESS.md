# IngotCluster Consumer Awareness

## Target Audience

| Segment | Who they are | Why they care |
|---------|-------------|---------------|
| Stacks node operators | libcluster integration | Live membership via Zenoh, not static lists |
| sBTC relay operators | Distributed relay coordination | Iroh DHT + Zenoh pub/sub |
| dApp developers | Distributed off-chain workers | FLAME backend with auto-discovery |
| Elixir teams | Already using libcluster | Drop-in replacement for static `config[:nodes]` |

## Awareness Channels

### Stacks Ecosystem
- **Stacks Forum:** libcluster strategy tutorial, live membership examples
- **Stacks Discord:** Q&A, demos, office hours
- **Stacks GitHub:** Issues, discussions, PRs

### Elixir Ecosystem
- **Elixir Forum:** "Replacing static node lists with Zenoh in IngotCluster"
- **Hex.pm:** Package description, docs, changelogs
- **GitHub:** Issues, discussions, stars, forks

### Social Media
- **Twitter/X:** Demo videos, benchmark screenshots
- **Reddit r/elixir:** Cross-post tutorials
- **YouTube:** Full demo screencast

## Content Strategy

### Blog Posts / Tutorials
1. **"Live libcluster Membership for Stacks with IngotCluster"**
   - Zenoh key subscriptions for live membership
   - Replacing static `config[:nodes]`
   - `ingot stacks peers` CLI walkthrough
   - Target: Stacks node operators

2. **"Distributed Stacks Indexer with IngotCluster + Crucible"**
   - Distributed block indexer example
   - FLAME backend for Stacks overlay
   - Cross-cloud worker provisioning
   - Target: dApp developers

3. **"sBTC Relay Coordination with IngotCluster"**
   - Zenoh pub/sub for relay status
   - Relay status aggregation
   - Integration with Crucible for provisioning
   - Target: sBTC relay operators

### Demo Videos
- **5 min:** Live libcluster membership demo
- **5 min:** Distributed indexer with FLAME

### Benchmark Publications
- `benchmark/CLUSTER_THROUGHPUT.md` — Zenoh pub/sub message rates
- `benchmark/MEMBERSHIP_LATENCY.md` — Time-to-discovery for new nodes

## Adoption Metrics

| Metric | Baseline | 30-day target | 90-day target |
|--------|----------|---------------|---------------|
| Hex downloads | 0 | 150+ | 800+ |
| GitHub stars | 0 | 30+ | 150+ |
| Stacks Forum replies | 0 | 5+ | 20+ |
| Blog post views | 0 | 400+ | 1,500+ |
| Demo video views | 0 | 150+ | 800+ |

## Timeline

### Week 1-2
- [ ] Publish libcluster tutorial
- [ ] Post Stacks Forum thread
- [ ] Record membership demo

### Week 3-4
- [ ] Publish distributed indexer tutorial
- [ ] Post Elixir Forum thread
- [ ] Submit Reddit r/elixir cross-post

### Week 5-8
- [ ] Publish sBTC relay coordination guide
- [ ] Monitor and respond to feedback
- [ ] Update benchmarks

## Key Messages

**For Stacks operators:**
> "Replace static node lists with live Zenoh-based membership. IngotCluster gives you a self-healing cluster data plane for Stacks nodes."

**For Elixir developers:**
> "The only Elixir cluster package combining Iroh DHT, Zenoh pub/sub, libcluster strategies, and FLAME backend. Drop-in replacement for static config."

## Competitive Positioning

| Competitor | Gap we fill |
|------------|-------------|
| Static libcluster configs | Live Zenoh-based membership |
| Generic libp2p wrappers | Elixir-native, Phoenix/FLAME integration |
| Single-backend clusters | Iroh + Zenoh in one package |
| No FLAME integration | Built-in FLAME backend for distributed workers |

**Our advantage:** Only Elixir package combining Iroh DHT, Zenoh pub/sub, libcluster strategies, and FLAME backend in a single cluster package.

---

*This document is part of the Elixir Distributed Stack consumer awareness strategy.*
