# WP-2: The READMEs, the audit and the test counts
Owner: coordinator. Status: done.

## Changed
- `README.md`: "a one-time 5% tax on the whole net worth of Californians worth $1 billion or more" (V-31); the BSZ part names NBER and says "This OPA's main estimate, $106.8 billion, nets it of the income tax it changes (not the authors' headline, which is the wealth tax alone)" (A-22); the RJKDC part cites "Jaros and Rauh, NBER chapter c15504 (September 2026), the revision of the March 2026 version by Rauh, Jaros, Kearney, Doran and Cosso (SSRN 6340778; SSRN is a preprint site)" (A-10); the Status table's Tests column links each materials page's Tests section instead of the stale counts, the comparison row adds "explorer with two slider panels", and a sentence under the table defines CI and says why the counts are not repeated (A-23, E-08, E-32, V-32, E-30); `{targets}` and "twin" defined in the sentence under the layout tree (E-30, KG).
- `bsz-analysis/README.md` line 10: the review link's heading adds "(this OPA's net total; BSZ's headline is the wealth tax, about $100 billion)" (A-22). The include block is untouched.
- `rjkdc-analysis/README.md`: the intro cites Jaros and Rauh as the authors of the reproduced version and the five authors as the first version's (A-10); the citation block's title is "The Net Present Value of the California Billionaire Tax Act" (A-09).
- `comparison/README.md`: a line under the review heading says whose number each of the two main estimates is (A-22); Open Output describes the explorer's one setting and the horizon sliders (E-01); "The reproduction" says the March inputs are the ones the common function takes one by one and that the September code and data are in the same public repository (A-02); "export contract", "Python twin" and "anchor" defined at first use (E-31, KG).
- `AUDIT.md`: reconciliation step 8 points to the materials page's count instead of "214 expectations" (E-08); the reconciliation vector is `1-3-3-3-3-3-3-2-3`, "so the three vectors are now identical" (E-09); CI defined in the step 8 "next level" cell (E-30).
- `.claude/skills/opa-review-loop/CONTENT-MAP.md` line 9: the same measure phrase as the README (V-31, also-on).

Checks run: the plan's greps (no "above $1 billion", no "561"/"179 expectations"/"214 expectations", no "1-3-2-2-2", no "with Kearney" in the two READMEs, "California Billionaire" in the RJKDC README, no "settings for the output"); no em or en dash added; `check_links.py` reports nothing new in these files.

## Needs a local render
- none

## Needs a follow-up (files outside the package)
- none

## Could not do
- Nothing in the package. (The comparison README has no "Rauh anchor" phrase; the anchor gloss went on the `anchors.csv` line.)

## Noticed on the way (not changed)
- `bsz-analysis/VERIFY-AUGUST.md` says the suite "has since grown to 561 expectations"; it is a dated record and the plan leaves it.
- The materials pages' Tests sections are linked as `materials.html#tests`; Quarto gives the "## Tests" heading that id on all three pages.
