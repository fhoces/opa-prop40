# DATA-SOURCES.csv: what the columns mean

`DATA-SOURCES.csv` (this directory, and the equivalent file in `rjkdc-analysis/`) is a
tracked, human- and machine-readable manifest of every source file the pipeline reads or may
read, one row per file. It is committed; the source files it describes are not (they live under
the gitignored `original-materials/`).

| Column | Meaning |
|---|---|
| `file` | Path relative to this side's directory. |
| `side` | `bsz` (Boll, Saez and Zucman, who support the measure) or `rjkdc` (Rauh et al., who oppose it). |
| `provider` | Who produced the file. |
| `obtained_via` | `public-download` (fetched from a public URL), `author-shared` (given to us directly by a paper's authors, not publicly posted), `re-pull` (an independent extraction from a primary public data source, e.g. SEC EDGAR, that stands in for a workbook-cached figure), or `git-clone` (a public code repository cloned at a pinned commit; `sha256` then holds the commit SHA). |
| `date_obtained` | When we got the file (best available; file mtime where the original download date wasn't otherwise recorded). |
| `url_or_contact` | Public URL for `public-download`/`re-pull`; a contact/channel description for `author-shared`; "not recorded" where the original download URL is unknown. |
| `sha256` | SHA-256 of the file we have, so anyone can re-verify their own copy against ours without either file leaving disk. |
| `terms` | What we're allowed to do with it: redistribute the file itself, publish figures/tables derived from it, and how to cite it. Phase 1 defaults every row to `do-not-redistribute` (the conservative default for a copyrighted PDF or an authors' workbook); refine per-file as actual terms become known, especially once author-shared data arrives with its own conditions. |
| `feeds` | Which workbook sheet, `tar_target`, or pipeline stage the file replaces or feeds. `reference only` means the pipeline doesn't read it programmatically (it's quoted or cited in prose). |
| `status` | `available` (file is present locally) or `missing`/`pending` for a slot we're expecting but don't have yet. |

## The `author-shared` convention

Either paper's authors (BSZ, or Rauh et al.) may share raw data or code that never appears on a
public page: SEC filings extracts, an internal spreadsheet, a data appendix sent by email. Two
items have arrived, both on 2026-09-23 and both recorded in the sides' `DATA-SOURCES.csv`:

- BSZ side: a confidential replication bundle of code and data
  (`author-shared/2026-09-23_bsz-replication-code-data/`, `obtained_via=author-shared`; re-analysis
  permitted, no public sharing). Not yet wired into any `tar_target`.
- RJKDC side: the authors' public GitHub repository `bjaros20/wealth_tax` (MIT licence), cloned at
  commit `25e84dd` (`author-shared/2026-09-23_wealth_tax-repo/`, `obtained_via=git-clone`). It is
  public, not author-shared in the sense above; it sits in the author-shared slot only for
  convenience, because the authors pointed us to it and the pipeline resolves it from there
  (`RAUH_REPO_DIR`).

- **Where it goes**: `<side>/original-materials/author-shared/<YYYY-MM-DD>_<short-desc>/`, e.g.
  `bsz-analysis/original-materials/author-shared/2026-10-05_bsz-sec-panel/`. This sits
  under the already-gitignored `original-materials/`, so author-shared files are never
  committed, and anything derived from them (CSVs, `*.sqlite` extracts) stays gitignored too;
  the existing root `.gitignore` patterns (`**/original-materials/`, `*.sqlite`) already cover
  both without any change.
- **Record it**: add a row to this side's `DATA-SOURCES.csv` with `obtained_via=author-shared`,
  the date received, a contact description in `url_or_contact` (e.g. "email from J. Rauh,
  2026-10-05"), the SHA-256, and specific `terms` (author-shared data often comes with tighter
  restrictions than a public PDF, so confirm with the sender rather than defaulting to
  `do-not-redistribute`).
- **How the pipeline uses it**: see "Future: author-shared raw data" in `../PLAN.md` for how a
  later phase wires an author-shared file into the pipeline through one path-resolver per side,
  the same pattern `BSZ_VINTAGE` already establishes for choosing between the May and August
  workbooks.
