# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

# Ellison was a CA resident only through ~mid-2023 per Forbes (paper note 2);
# he is excluded from all CA-billionaire aggregates throughout the panel.
ELLISON_FORBES_ID <- "larry-ellison"
compute_data_sec_agg <- function(data_sec_all,
                                 exclude_ids = ELLISON_FORBES_ID,
                                 m_to_b = 1000) {
  # The computation is the shared query sql/02_data_sec_agg.sql (run here in
  # an in-memory SQLite database; the pipeline runs it in
  # data-raw/workbook.sqlite, see R/workbook_db.R and read_data_sec_agg()).
  # It sums 27 metric columns of data_sec_all by year after two filters:
  #
  #   1. exclude_ids (Ellison by default) are dropped.
  #   2. Exact re-pastes are dropped. August's data_sec_all has a 4-row block
  #      (sytse-sid-sijbrandij, rihanna, tom-preston-werner, trae-stephens;
  #      year 2025) accidentally pasted twice at the very tail of the sheet
  #      (rows 1338-1341 re-appearing at 1342-1345, byte-identical or
  #      near-identical). This is a genuine data-entry error in the workbook,
  #      not a second legitimate entry: dropping the second copy reproduces
  #      the workbook's OWN data_sec_agg cache (n=240, forbes_worth=
  #      2054.82B) exactly, and matches the paper's own stated count
  #      (Appendix A: "we identify 240 billionaires with total wealth of $2055
  #      billion"). Distinct same-slug entries with a DIFFERENT forbes_worth
  #      (e.g. stewart-resnick in 2022, two separately-tracked Forbes amounts,
  #      $8.0B and $5.256B, present in both May and August) are left alone:
  #      keying the filter on (year, forbes_id, forbes_worth) catches only
  #      the true re-paste.
  #
  # Before the SQL step this was dplyr: filter, !duplicated(), then
  # group_by(year) |> summarise(n = n(), across(cols, sum(na.rm) / 1000)).
  # tests/testthat/test-sql-workbook.R keeps that version as the reference.
  if (!isTRUE(all.equal(m_to_b, 1000))) {
    stop("sql/02_data_sec_agg.sql converts $ million to $ billion; m_to_b must be 1000")
  }
  con <- .workbook_con(
    tables = workbook_input_tables(data_sec_all = data_sec_all, exclude_ids = exclude_ids),
    sql_files = workbook_sql_file("02_data_sec_agg.sql")
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  .read_data_sec_agg(con)
}
