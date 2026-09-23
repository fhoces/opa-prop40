# opa-prop40

An [Open Policy Analysis (OPA)](https://www.bitss.org/) of the two rival revenue analyses of
California's 2026 Proposition 40 (the Billionaire Tax Act, a one-time 5% tax on net worth above
$1bn).

- **Supporting**: Boll, Saez & Zucman (BSZ), NBER WP 35218, May 2026, revised August 2026, with
  an Excel workbook `BSZ_MainTablesFigures.xlsx`.
- **Opposing**: Rauh, Jaros, Kearney, Doran & Cosso, Hoover Institution, 17 March 2026
  (SSRN 6340778). PDF only.

The end state is a full OPA for each side, plus a comparison layer that puts both on one
input-to-output chain, published as a website. See `PLAN.md` for the phased build plan.

## Layout

```
opa-prop40/
├── supporting-analysis/   BSZ replication pipeline (R, {targets}), imported from CAWT-BSZ
├── opposing-analysis/     Rauh et al. analysis (placeholder, phase 2)
└── comparison/            cross-side comparison layer (placeholder, later phase)
```

## Status

Phase 1 complete: repo skeleton, CAWT-BSZ imported with history, workbook vintage made
selectable (August default / May via `BSZ_VINTAGE=may`), May baseline re-verified, August
re-verified and discrepancies documented (no fixes), CI stub added. See
`supporting-analysis/VERIFY-AUGUST.md` for the August findings.

Not yet started: Python twin, shared SQL layer, the Rauh et al. replication, the comparison
layer, and the public website.

## Sources policy

Third-party PDFs, workbooks, SSRN files and anything extracted from them (CSV, `*.sqlite`) are
never committed to this repo. Each side's `README.md` records the source URL and SHA-256 of
every file it depends on instead. See `supporting-analysis/README.md` and
`opposing-analysis/README.md`.
