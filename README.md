# EVE Platform — Orchestration

Top-level orchestration layer for the EVE Platform, a multi-module AI-assisted
EVE Online tooling platform running on a Raspberry Pi 5.

## Repository Structure

This repo contains only cross-module orchestration concerns: the environment
Makefile and shared documentation. Each module is an independent git repository
cloned as a sibling directory:
~/projects/eve/
├── eve-orchestration/    ← this repo (Makefile, docs)
├── platform/             ← daithib-eve/eve-platform
├── trader/               ← daithib-eve/eve-trader
├── ledger/               ← daithib-eve/eve-ledger (not started)
└── industry/             ← daithib-eve/eve-industry (not started)

## Why Polyrepo

Each module is an independent deployable with its own release cadence, test
suite, and dependency set. Keeping them in separate repositories enforces the
architectural boundary that matters operationally: a change to eve-trader cannot
accidentally break eve-platform's CI, and a dependency upgrade in eve-ledger
does not require a coordinated release across every module.

The orchestration layer exists as a separate thin repo rather than being absorbed
into eve-platform because environment-level concerns (bringing up the full dev
stack, cross-module runbooks) are not owned by any single module. Eve-platform
owns the shared infrastructure; this repo owns the developer experience of
working across all of them simultaneously.

This structure also maps cleanly to how AI coding tools are used in this project.
Each Claude Code session operates within a single module repo, with project
knowledge scoped to that repo. The boundary prevents cross-module context
contamination mid-session and enforces the same ownership discipline that would
apply in a team environment where different engineers owned different services.

## Modules

| Module | Repo | Status | Purpose |
|---|---|---|---|
| eve-platform | daithib-eve/eve-platform | In progress | Shared infrastructure: ESI, OAuth, market data collection, scheduling |
| eve-trader | daithib-eve/eve-trader | MVP complete | Market arbitrage analysis and AI-powered shopping recommendations |
| eve-ledger | daithib-eve/eve-ledger | Designed | Personal trading ledger: wallet, assets, cost basis, P&L |
| eve-industry | daithib-eve/eve-industry | Phase 4 | Production planning and build cost analysis |

## Usage

```bash
# Bring up the full dev environment (all modules)
make dev-up

# Tear it down
make dev-down

# Check status
make dev-ps
```

See `Makefile` for all available targets.

## Hardware

Raspberry Pi 5, 8GB RAM, 256GB NVMe, aarch64, headless Raspberry Pi OS.
Production at `/opt/eve/`. Development at `~/projects/eve/`.
