"""Python twin of R/vintage.R: the literals that differ between the May and
August BSZ_MainTablesFigures.xlsx workbooks.

One environment variable, BSZ_VINTAGE ("august" by default, or "may"),
switches the workbook path (ingest_excel.xlsx_path_default) and every
vintage-dependent column letter, row offset and constant below, exactly as
in R. The comments in R/vintage.R explain where each literal comes from; this
file only restates the values.
"""
import os


def bsz_vintage():
    v = os.environ.get("BSZ_VINTAGE", "august")
    return "may" if v == "may" else "august"


# shortrunseries: column letters, keyed by concept name (see R/vintage.R).
SRS_COL = {
    "may": dict(
        K_ellison="K", Q_us_wealth="Q", V_share="V",
        top5_total="E", top5_wavoid="F", top5_company="G", share_public="H",
        n_us_citizen="I", n_ca="J", share_ellison="L", yoy_growth="M",
        cum2019="N", cum2022="O", cum2023="P",
        top5_yoy="R", top5_cum2019="S", top5_cum2022="T",
        ca_inctax="X", ca_inctax_per_wealth="Y", ca_inctax_total="Z", ca_inctax_share="AA",
        top5_sec_rate="AD", top5_sec_inctax="AE", top5_sec_share="AF",
        top3_sum="AG", top2_sum="AH",
        brin="AJ", page="AK", zuck="AL", ellison="AM", huang="AN",
    ),
    "august": dict(
        K_ellison="R", Q_us_wealth="X", V_share="AC",
        top5_total="K", top5_wavoid="L", top5_company="N", share_public="O",
        n_us_citizen="P", n_ca="Q", share_ellison="S", yoy_growth="T",
        cum2019="U", cum2022="V", cum2023="W",
        top5_yoy="Y", top5_cum2019="Z", top5_cum2022="AA",
        ca_inctax="AF", ca_inctax_per_wealth="AH", ca_inctax_total="AI", ca_inctax_share="AJ",
        top5_sec_rate="AO", top5_sec_inctax="AP", top5_sec_share="AQ",
        top3_sum="AR", top2_sum="AS",
        brin="AU", page="AV", zuck="AW", ellison="AX", huang="AY",
    ),
}


def srs_col(name, vintage=None):
    vintage = vintage or bsz_vintage()
    col = SRS_COL[vintage].get(name)
    if col is None:
        raise KeyError(f"No shortrunseries column mapped for '{name}' in vintage '{vintage}'")
    return col


def srs_summary_row(row_may, vintage=None):
    vintage = vintage or bsz_vintage()
    return row_may if vintage == "may" else row_may + 2


srs_growth_row = srs_summary_row


def bci_row(row_may, vintage=None):
    """billionairesCAinctax: August inserted one row at 16 and one at old 144."""
    vintage = vintage or bsz_vintage()
    if vintage == "may":
        return row_may
    if row_may <= 15:
        return row_may
    if row_may <= 143:
        return row_may + 1
    return row_may + 2


def bci_cell(bci, addr_may, vintage=None):
    """Read a May-numbered billionairesCAinctax address; only the row is remapped."""
    from excel_cells import split_addr, xls_cell
    col, row = split_addr(addr_may)
    return xls_cell(bci, f"{col}{bci_row(row, vintage)}")


def bci_sales_gross_up_rate(vintage=None):
    vintage = vintage or bsz_vintage()
    return 0.11 if vintage == "may" else 0.095


TAB5_CONST = {
    "may": dict(
        baseline_n=249, baseline_wealth=2182,
        page_wealth_B=276, page_private_B=13.4,
        thiel_wealth_B=28.9,
        hankey_wealth_B=8.15,
        kalanick_wealth_B=3.56,
        brin_wealth_B=254.6, brin_private_B=13.2,
        zuck_wealth_B=230.2, zuck_private_B=2.5,
        fang_wealth_B=1.5,
        huang_wealth_B=172, huang_private_B=2.84,
    ),
    "august": dict(
        baseline_n=250, baseline_wealth=2307,
        page_wealth_B=294.6, page_private_B=13.4,
        thiel_wealth_B=27.3,
        hankey_wealth_B=8.15,
        kalanick_wealth_B=3.56,
        brin_wealth_B=271.7, brin_private_B=13.2,
        zuck_wealth_B=210.3, zuck_private_B=2.5,
        fang_wealth_B=1.5,
        huang_wealth_B=170.9, huang_private_B=2.84,
    ),
}


def tab5_const(name, vintage=None):
    return TAB5_CONST[vintage or bsz_vintage()][name]


def lrs_current_row(vintage=None):
    return 51 if (vintage or bsz_vintage()) == "may" else 52


LRS_BASE_ROW = 8  # 1982, unchanged both vintages


def fig8_laffer_sheet(vintage=None):
    return "Fig8" if (vintage or bsz_vintage()) == "may" else "Fig9"
