# Bumble Bee TPM Project Memory

## Key Files
- `Pipeline_and_Org_Strategy.md` — Main strategy doc covering orgs, branching, pipeline, shared sandbox workflow, admin Git guide
- `CLAUDE.md` — Project context and key decisions
- `deployment-call-export.txt` — Feb 5 2026 call transcript, source of truth for architectural decisions
- `main_object.txt` — TPM data model objects with API names and dependencies

## Technical Decisions
- **5-org limit** for TPM package installs (unverified — could be 3-5, Tyler to confirm)
- **Git repo is source of truth**, not sandboxes
- **Shared dev sandbox** is the core challenge — manifest-based selective retrieve (`sf project retrieve start -m`) is the solution for admins
- **sfdx-git-delta (sgd)** for delta deploys between branches
- **SFDMU + Node.js wrapper** for data pipeline with ordered deployment
- **Metadata before data** rule at every promotion stage (KPIs reference custom fields)

## Data Model Load Order
Master Data → Assortments → CBP/KPIs → Funds/RBF → Promotions → Tactics → Claims

## Patterns
- When creating strategy docs, always cross-reference the call transcript for decision rationale
- Verification step catches misalignment between sections (e.g., data model lists not matching across sections)
