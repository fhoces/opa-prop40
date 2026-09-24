"""Python twin of R/nber_final.R."""
import csv


def extract_nber_final(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def compute_nber_ceiling(final_rows):
    dom = [r for r in final_rows if r["panel"] == "domestic"]
    intl = [r for r in final_rows if r["panel"] == "international"]
    removed = [r for r in dom if r["bucket"] == "removed_departed"]

    def s(rows, key):
        return sum(float(r[key]) for r in rows if r[key] not in ("", None))

    domestic_total_grown = s(dom, "face_tax_5pct") / 1e9
    removed_departed_total = s(removed, "face_tax_5pct") / 1e9
    ceiling_recomputed = domestic_total_grown - removed_departed_total
    international_net_worth = s(intl, "net_worth_usd") / 1e9

    return {
        "n_domestic": len(dom),
        "n_international": len(intl),
        "n_removed_departed": len(removed),
        "domestic_total_grown": domestic_total_grown,
        "removed_departed_total": removed_departed_total,
        "ceiling_recomputed": ceiling_recomputed,
        "international_net_worth": international_net_worth,
        "removed_names": [r["name"] for r in removed],
    }
