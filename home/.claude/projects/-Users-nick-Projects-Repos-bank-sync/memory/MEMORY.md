# Memory

## Project Context

- This repo is part of the `~/iCloud/home-budget` workspace
- The parent workspace has a YNAB MCP server for budget queries; this repo handles the bank scraping/sync pipeline
- CIBC scraper is WORKING end-to-end (login + 2FA + CSV download + parse + YNAB push)
- Tangerine and MBNA scrapers are still scaffolded/untested

## Key Technical Details

- CIBC SMS 2FA sender IDs: `242227`, `242225` (short codes, not 1-800 numbers)
- CIBC CSV format: no header row, columns are Date(YYYY-MM-DD), Description, Debit, Credit, CardNumber
- CIBC login opens on `secure.cibc.com`, dashboard lands on `cibconline.cibc.com` (different Ember apps)
- CIBC download page URL: `{origin}/ebm-resources/public/banking/cibc/client/web/index.html#/accounts/download`
- CIBC 2FA flow: "Didn't receive the code?" → "Use a different contact method" → select "Text" (value="1") → "Send code"
- `ynab` Python SDK is v4 (pydantic-based): use `PostTransactionsWrapper`, `NewTransaction`, `create_transaction`, `var_date` field
- `chat.db` SQLite approach works for reading SMS 2FA codes — Full Disk Access required
- Use `--window-position=2000,2000` to keep Playwright browser off-screen and avoid focus stealing
- Bank SPAs need `wait_until="domcontentloaded"` not `networkidle` (persistent connections prevent idle)
- Custom UI components (CIBC's radio buttons, etc.) intercept pointer events — click labels instead of inputs

## User Preferences

- Don't ask to run after fixes — just run automatically
- User wants browser to not steal focus while running
