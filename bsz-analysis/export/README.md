Export contract read by the comparison layer (`comparison/`), and nothing else from this side.

- `r/inputs.csv`: `input_id, version, description, value, unit, label, provenance, source, page`
- `r/outputs.csv`: `output_id, version, value, unit, printed_value, printed_page, abs_diff`

Same schema as `rjkdc-analysis/export/r/`. Written by the `export_*` targets in
`_targets.R` (functions in `R/export_contract.R`) from existing targets only: no new
computation. `version` is `ggss` (expert report, 20 Jul 2026), `bsz` (NBER WP 35218, Aug 2026)
or `both`. Pages are PDF pages. There is no `py/` export yet on this side.
