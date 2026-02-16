# Plan: TPM Deployment Pipeline & Org Strategy Document

## Context

Nick is the sole technical developer on the Bumble Bee Foods TPM implementation (Corrao Group). The team includes admins who will do full git workflow but need clear, step-by-step instructions. The project uses Salesforce TPM (Consumer Goods Cloud) with the MyFirst TPM framework, deployed across 4 environments within a 5-org package install limit. Scratch orgs are not viable due to this limit. All devs/admins share a single dev sandbox, creating the core challenge: how to retrieve, commit, and deploy only YOUR changes without pulling in everyone else's noise.

**Deliverable:** A standalone strategy document (`Pipeline_and_Org_Strategy.md`) in this planning workspace that covers org strategy, branching, deployment pipeline, shared sandbox workflow, and data/metadata synchronization. Written to be Bumble Bee-specific but structured so it can be adapted for future TPM projects.

---

## Document Structure (what we'll write)

### Section 1: Org Strategy
- **4 active orgs** (within 5-org TPM package limit):
  - `CG-DEV` (Developer Pro) — primary development sandbox
  - `QA` (Partial Copy) — QA testing, SIT, integration validation
  - `UAT-DEMO` (Full Copy) — customer demos, sprint reviews, UAT
  - `PROD` (Production) — go-live target
- **INT-DEV** (Developer Pro) — Caelius integration team's parallel dev box (5th org)
- Sandbox refresh cadence and guidelines
- Who has access to what (table format)

### Section 2: Repository Structure
Single repo, two deployment tracks:
```
project-repo/
├── force-app/              # SFDX source format (metadata)
│   └── main/default/       # Standard SFDX layout
├── data/                   # SFDMU data deployment configs
│   ├── export-configs/     # SFDMU export.json per object group
│   └── snapshots/          # Exported data snapshots (versioned)
├── scripts/                # Helper scripts for common operations
├── manifest/               # package.xml templates for targeted retrieval
├── .github/workflows/      # GitHub Actions (future automation)
├── docs/                   # Process documentation
├── sfdx-project.json
└── README.md
```

### Section 3: Branching Strategy
Branch-to-org mapping:
- `main` → Production
- `uat` → UAT-DEMO org
- `qa` → QA org
- `dev` → CG-DEV org (integration branch)
- `feature/*` → branched off `dev`, merged back via PR

Flow: `feature/* → dev → qa → uat → main`

Key rules:
- All work starts as a feature branch off `dev`
- PRs required at every promotion stage (feature→dev, dev→qa, qa→uat, uat→main)
- Nick is the gatekeeper for all PRs into `qa` and above
- Feature branches named: `feature/SPRINT-XX-short-description`

### Section 4: Shared Dev Sandbox Workflow (the core challenge)

**The Problem:** Multiple people making changes in the same org. `sf project retrieve start` (source tracking) pulls ALL changes, not just yours.

**The Solution — "Manifest-Based Selective Retrieve":**

Each person maintains awareness of what they changed and retrieves only those components. Three methods, from simplest to most powerful:

#### Method A: Direct component retrieval (recommended for admins)
```bash
# Retrieve specific metadata by type
sf project retrieve start -m "CustomField:Account.My_New_Field__c"
sf project retrieve start -m "Layout:Account-Account Layout"
sf project retrieve start -m "FlexiPage:My_Lightning_Page"

# Retrieve by file path (if you know the path from a previous retrieve)
sf project retrieve start -p force-app/main/default/objects/Account/fields/My_New_Field__c.field-meta.xml
```
- Include a **cheat sheet** of common metadata type names (CustomField, Layout, FlexiPage, PermissionSet, etc.)
- Admins document what they changed in their PR description

#### Method B: Manifest-based retrieval (for larger features)
```bash
# Create a package.xml listing exactly what you need
sf project retrieve start -x manifest/my-feature.xml
```
- Provide a `manifest/template.xml` with common component types
- Admin copies it, fills in their components, retrieves

#### Method C: Full retrieve + selective staging (Nick's power-user workflow)
```bash
sf project retrieve start            # Pulls everything
git add -p                            # Interactive staging (select hunks)
git checkout -- <files-not-yours>    # Discard others' changes
```

#### Keeping the dev box clean:
- **"Leave no trace" rule**: If you create something experimental, delete it when done
- **Weekly dev box audit**: Nick runs a diff against `dev` branch to identify orphaned metadata
- **Naming convention**: All new components include a ticket/sprint prefix in their description field (not API name — API names can't change later)

### Section 5: Git Workflow for Admins (step-by-step)
Exact copy-paste commands for the full cycle:
1. Start work: `git checkout dev && git pull && git checkout -b feature/S03-new-promo-layout`
2. Make changes in Salesforce UI
3. Retrieve YOUR changes: (Method A or B above)
4. Review what you're about to commit: `git status` and `git diff`
5. Stage and commit: `git add <files>` then `git commit -m "S03: Add promotion page layout"`
6. Push: `git push -u origin feature/S03-new-promo-layout`
7. Open PR on GitHub (targeting `dev`)
8. After PR merged, clean up: `git checkout dev && git pull && git branch -d feature/S03-new-promo-layout`

Include a **troubleshooting FAQ**:
- "I accidentally retrieved someone else's changes" → `git checkout -- <file>`
- "I have merge conflicts" → step-by-step resolution or "ask Nick"
- "Source tracking is out of sync" → `sf project reset tracking -p`

### Section 6: Deployment Pipeline

**Metadata pipeline** (SFDX + sfdx-git-delta):
- On PR merge to `dev`: validate deployment to CG-DEV (already there, but confirms the source is deployable)
- On PR merge to `qa`: delta deploy to QA org using sfdx-git-delta (`sgd`) to generate a package.xml from the diff between `qa` and `dev`
- On PR merge to `uat`: delta deploy to UAT-DEMO
- On PR merge to `main`: delta deploy to Production (with manual approval gate)

**Data pipeline** (SFDMU wrapper):
- Data deployments are triggered manually or via labeled PRs
- Deployment order is handled by the Node.js wrapper (already built)
- Data changes committed to `data/` directory
- Data PRs follow the same branch flow but can move independently of metadata

**Validation gates at each stage:**
- `dev → qa`: Unit tests pass, package validates
- `qa → uat`: Smoke test checklist (manual for now, automated later)
- `uat → main`: UAT sign-off + Nick approval

**Dependency rule:** If a data deployment references new metadata (e.g., a KPI referencing a new custom field), the metadata PR must be merged and deployed FIRST at every stage.

### Section 7: Hotfix Process
```
main (identify bug)
  └── hotfix/urgent-fix (branch off main)
       → fix → PR to main → deploy to PROD
       → cherry-pick into uat, qa, dev
```
- Hotfixes are the ONLY branches that can go directly to main
- Must be back-merged into ALL lower branches

### Section 8: Release Cadence
- **Dev → QA**: As often as needed (daily is fine)
- **QA → UAT**: End of sprint (planned release window)
- **UAT → Prod**: After UAT sign-off, controlled release
- **Customer demo window**: Last 2-3 days of each sprint in UAT-DEMO only

### Section 9: Scalability Notes (for future projects)
- Parameterize org names, branch names, team roles
- Org strategy scales to any 4-5 sandbox setup
- Shared sandbox workflow applies to any TPM project with package limits
- Data pipeline ordering (SFDMU wrapper) is reusable across CG Cloud projects
- The branching model is standard GitFlow-lite — works anywhere

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `Pipeline_and_Org_Strategy.md` | **CREATE** — the main deliverable, standalone strategy document |
| `CLAUDE.md` | **UPDATE** — add reference to the new strategy doc |

## Verification
- Read through the completed document for internal consistency
- Cross-reference against the deployment call transcript decisions
- Verify the org count stays within 5-org limit
- Ensure the admin workflow section has concrete, runnable commands
- Confirm data/metadata dependency rules align with the TPM data model (Templates → Instances → KPIs)
