"""Capital gains on Form 4 sales: the sequential cost-basis step (Python twin).

Run from bsz-analysis/, after sql/09_form4_income.sql:

    python py/form4_basis.py

Reads form4_basis_input from data-raw/bundle.sqlite and writes two tables
back, which sql/10_form4_annual.sql uses:

  form4_kg           one row per sale: total_basis, kg, kg_short, kg_long
  form4_basis_held   one row per owner, issuer and year: the cost basis of the
                     shares still held after the year's last trade

The R twin is R/form4_basis.R (same algorithm, same tables); the checker
compares the two.

Why this is not SQL: each sale draws shares from the lots acquired before
it, and what is left of each lot depends on every earlier sale. A query
sees all rows at once; this is a loop with state (the inventory of lots).

The rules, per owner and issuer, trades in the order of seq (date,
acquisitions before sales on the same day, then file order):
  * an option exercise or RSU vesting (M, A) with shares_option > 0 adds a
    lot of shares_option shares at the day's closing price (prccd);
  * an open-market purchase (P, A) with shares > 0 adds a lot at the
    purchase price;
  * a withholding for tax (F, D) with shares_option > 0 adds a lot of
    shares_option shares at the withholding price;
  * a sale (S, D) with shares > 0 uses the lots with the highest cost per
    share first. Share counts and costs of the lots are first put on the
    sale's split basis: a lot's adjustment factor is its ajexdi over the
    sale's ajexdi (1 when either is missing or the sale's is not positive);
    the lot holds shares x factor shares at cost / factor. Each share taken
    adds its cost to the basis, short-term when the lot is at most 365 days
    old, long-term otherwise. A sale larger than the inventory counts the
    rest as long-term with no basis. With no lots at all, the whole sale is a
    long-term gain. kg = sale - basis; kg_short and kg_long split it.
  * after the last trade of each year, the basis of the remaining lots
    (shares x cost, unadjusted, skipping unknown costs) is recorded.
Missing numbers (NULL, here NaN) propagate through the arithmetic as R's NA
does, so a lot with an unknown cost makes the basis of the sale that uses it
unknown.
"""
import math
import sqlite3
import sys
from datetime import date
from itertools import groupby
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import sqlite_path  # noqa: E402

NAN = float("nan")


def _f(v):
    return NAN if v is None else float(v)


def _isna(x):
    return x is None or (isinstance(x, float) and math.isnan(x))


def _div(a, b):
    """a / b with IEEE semantics (R's): x / 0 is +-Inf, 0 / 0 is NaN."""
    try:
        return a / b
    except ZeroDivisionError:
        if a == 0 or math.isnan(a):
            return NAN
        return math.copysign(math.inf, a) * math.copysign(1.0, b)


def _days(d1, d0):
    return (date.fromisoformat(d1) - date.fromisoformat(d0)).days


def _sell(inventory, row):
    """Apply one sale to the inventory; returns (new inventory, result dict)."""
    shares_to_sell = _f(row["shares_sold"])
    sale_price = _f(row["price_per_share"])
    sale_date = row["transaction_date"]
    sale_ajexdi = _f(row["ajexdi"])
    total_sale = shares_to_sell * sale_price
    if not inventory:
        return inventory, {"total_basis": 0.0, "kg": total_sale, "kg_short": 0.0,
                           "kg_long": total_sale}
    lots = []
    for lot in inventory:
        aj = lot["ajexdi"]
        if not _isna(aj) and not _isna(sale_ajexdi) and sale_ajexdi > 0:
            adj = _div(aj, sale_ajexdi)
        else:
            adj = 1.0
        lots.append(dict(lot, adj=adj, basis_adj=_div(lot["basis"], adj),
                         shares_adj=lot["shares"] * adj))
    # Highest cost first; unknown costs last; ties keep their order (stable).
    lots.sort(key=lambda x: (math.isnan(x["basis_adj"]),
                             0.0 if math.isnan(x["basis_adj"]) else -x["basis_adj"]))
    remaining = shares_to_sell
    total_basis = basis_short = basis_long = 0.0
    sold_short = sold_long = 0.0
    kept = []
    for lot in lots:
        if remaining > 0:
            take = min(lot["shares_adj"], remaining)
            total_basis = total_basis + take * lot["basis_adj"]
            remaining = remaining - take
            if sale_date is None or lot["date"] is None:
                held = None
            else:
                held = _days(sale_date, lot["date"])
            if held is None or held > 365:
                sold_long = sold_long + take
                basis_long = basis_long + take * lot["basis_adj"]
            else:
                sold_short = sold_short + take
                basis_short = basis_short + take * lot["basis_adj"]
            if lot["shares_adj"] > take:
                kept.append({"shares": lot["shares"] - _div(take, lot["adj"]),
                             "basis": lot["basis"], "date": lot["date"],
                             "ajexdi": lot["ajexdi"]})
        else:
            kept.append({k: lot[k] for k in ("shares", "basis", "date", "ajexdi")})
    if remaining > 0:
        sold_long = sold_long + remaining
    kg = total_sale - total_basis
    kg_short = sold_short * sale_price - basis_short
    kg_long = sold_long * sale_price - basis_long
    return kept, {"total_basis": total_basis, "kg": kg, "kg_short": kg_short,
                  "kg_long": kg_long}


def run_basis(rows):
    """rows: dicts sorted by owner_cik_1, issuer_cik, seq. Returns (kg rows, basis rows)."""
    kg_rows, basis_rows = [], []
    for (owner, issuer), group in groupby(rows, key=lambda r: (r["owner_cik_1"], r["issuer_cik"])):
        group = list(group)
        inventory = []
        for i, row in enumerate(group):
            code, typ = row["code"], row["type"]
            new_lot = None
            if code == "M" and typ == "A":
                if not _isna(row["shares_option"]) and row["shares_option"] > 0:
                    new_lot = (row["shares_option"], row["prccd"])
            elif code == "P" and typ == "A":
                if not _isna(row["shares_purchased"]) and row["shares_purchased"] > 0:
                    new_lot = (row["shares_purchased"], row["price_per_share"])
            elif code == "F" and typ == "D":
                if not _isna(row["shares_option"]) and row["shares_option"] > 0:
                    new_lot = (row["shares_option"], row["price_per_share"])
            if new_lot:
                inventory.append({"shares": float(new_lot[0]), "basis": _f(new_lot[1]),
                                  "date": row["transaction_date"], "ajexdi": _f(row["ajexdi"])})
            if code == "S" and typ == "D":
                if not _isna(row["shares_sold"]) and row["shares_sold"] > 0:
                    inventory, res = _sell(inventory, row)
                    kg_rows.append({"row_id": row["row_id"], **res})
            last_in_year = i == len(group) - 1 or group[i + 1]["year"] != row["year"]
            if last_in_year:
                snap = 0.0
                for lot in inventory:
                    v = lot["shares"] * lot["basis"]
                    if not math.isnan(v):
                        snap = snap + v
                basis_rows.append({"owner_cik_1": owner, "issuer_cik": issuer,
                                   "year": int(row["year"]), "total_basis": snap})
    return kg_rows, basis_rows


def _nan_to_null(x):
    return None if isinstance(x, float) and math.isnan(x) else x


def main(db=None):
    con = sqlite3.connect(db or sqlite_path())
    con.row_factory = sqlite3.Row
    rows = [dict(r) for r in con.execute(
        "SELECT * FROM form4_basis_input ORDER BY owner_cik_1, issuer_cik, seq")]
    kg_rows, basis_rows = run_basis(rows)
    with con:
        con.execute("DROP TABLE IF EXISTS form4_kg")
        con.execute("CREATE TABLE form4_kg (row_id INTEGER, total_basis REAL, kg REAL, "
                    "kg_short REAL, kg_long REAL)")
        con.executemany("INSERT INTO form4_kg VALUES (?, ?, ?, ?, ?)",
                        [(r["row_id"], *(_nan_to_null(r[k]) for k in
                                         ("total_basis", "kg", "kg_short", "kg_long")))
                         for r in kg_rows])
        con.execute("DROP TABLE IF EXISTS form4_basis_held")
        con.execute("CREATE TABLE form4_basis_held (owner_cik_1 TEXT, issuer_cik INTEGER, "
                    "year INTEGER, total_basis REAL)")
        con.executemany("INSERT INTO form4_basis_held VALUES (?, ?, ?, ?)",
                        [(r["owner_cik_1"], r["issuer_cik"], r["year"], r["total_basis"])
                         for r in basis_rows])
    con.close()
    print(f"form4_kg: {len(kg_rows):,} sales; form4_basis_held: {len(basis_rows):,} "
          "owner-issuer-years")


if __name__ == "__main__":
    main()
