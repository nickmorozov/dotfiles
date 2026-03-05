# Tax Project Memory

## Household

- Nick (Mykola Morozov) and Mariia Morozova, married, Langley BC
- Property: 110-9507 208 St, Langley BC V1M 2Z1
- Tax software: Wealthsimple Tax (both filers)

## Nick's 2025 Income Structure

- **Jan–Sep**: Self-employed contractor via Corrao Group (16 payments, $148K gross through Wise CAD)
- **Sep onwards**: Incorporated as **Enum Solutions Inc** (CCPC, 40%+ voting shares)
- Corp revenue (Oct–Dec): $45,955 from Corrao Group
- Corp paid Nick $40K salary (salary vs dividend classification TBD with accountant)
- EI exempt (owner-manager with 40%+ voting shares)
- CPP maxed on self-employment side ($8,068 total); corp CPP withheld = overpayment refund ~$2,172
- Total gross: ~$194K; effective tax rate ~32.9%; estimated take-home ~$123K

## Mariia's 2025 Income

- Community Savings Credit Union: T4 #1 $50,643 + T4 #2 $19,341
- Cypress Bowl Recreations: T4 $4,423 (seasonal)
- Total: ~$74,407

## Tax Obligations (2025)

- Nick personal tax owing: ~$50,170 (due Apr 30, 2026)
- Corp payroll remittance: ~$8,858 (OVERDUE — pay ASAP from corp)
- Payroll penalty + interest: ~$923
- Corp tax (Enum Solutions T2): ~$254
- **Total cash needed: ~$60,206**
- Taxes account (YNAB/Wealthsimple): ~$140K — well-funded

## 2024 Tax Return (filed Feb 26, 2025)

- Nick owed $34,815 for 2024
- Total income: $202,703 (employment $77,752 + professional $122,946 + EI $2,004)
- RRSP deduction: $321 (Sun Life $1,375 contribution Mar-Dec 2024)
- Federal tax: $39,957; BC tax: $19,519
- Claimed: LASIK $3,690 medical, Kars4Kids $550 donation, employment expenses $2,808

## YNAB Setup

- Budget: "last-used" works
- Key accounts: Wealthsimple (main), Scotiabank (checking), Corp (off-budget tracking)
- Taxes account: off-budget, Wealthsimple savings
- Income category: "Inflow: Ready to Assign" (id: 6dbf8c0a-a17d-432b-82d6-eb80f84899d5)
- Corp account id: ca75ba0d-b1d2-4942-86b2-f2ae0220d869
- Mariia's accounts all closed in YNAB (mid-2025)
- MCP config: uvx from git+https://github.com/nickmorozov/mcp-ynab, token in .env

## Key Files

- `Enum_Solutions_2025_Tax_Summary.xlsx` — 3 sheets: main estimates, payroll remittance calc, total tax estimate. Read with python3 zipfile+xml (no openpyxl installed)
- `.xlsx` reading: use zipfile + xml.etree approach, openpyxl not available on this machine

## Mortgage (First National)

- Rate: Prime - 0.90% (variable); maturity Aug 2028
- 2024 interest paid: $41,512; principal paid: $12,284
- Closing balance end 2024: $719,178
- Monthly payment: $4,647 (P&I $4,307 + tax $339)
