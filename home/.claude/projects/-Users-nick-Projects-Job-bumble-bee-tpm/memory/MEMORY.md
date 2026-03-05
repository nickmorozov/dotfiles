# MEMORY.md

## GitHub Actions
- `npm install --global <pkg>` in GH Actions doesn't reliably add binaries to PATH in subsequent steps (especially with `actions/setup-node`). Fix: add `echo "$(npm prefix -g)/bin" >> "$GITHUB_PATH"` after the install. Do NOT use `npx <binary>` — npx resolves by package name, not binary name (e.g., `npx sgd` fails because the package is `sfdx-git-delta`, not `sgd`).
- When a multi-job workflow has a notify job, it must `needs:` ALL upstream jobs (including delta generation), not just the deploy jobs — otherwise notify is skipped when early jobs fail.

## Project Conventions
- Source path: `src/myfirst-tpm/` (NOT `force-app/`)
- Node version: 23 (used across all CI workflows)
- Test command: `npm test` runs `test:lwc && test:apex` (requires `sf` CLI for apex). CI workflows use `npm run test:lwc` (Jest only, no `sf` needed).
- Branch-to-org mapping: `dev` → CG-DEV + CG-INT, `qa` → QA, `uat` → UAT-DEMO, `main` → PROD
