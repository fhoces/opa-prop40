# The survey experiment

The project's survey asks which of two proposed values of each disputed input is more credible.
An experiment randomizes, at the click on a survey link, whether the form names the two studies
and shows a page on how the two estimates differ. Everything about it lives in this folder,
except the two data files the site reads (`../data/survey-links.csv`, the four forms' links, and
`../data/survey-config.csv`, the draw count's address) and the site code that uses them
(`../R/site.R`, from `read_survey_links()` to `survey_share_page()`, which writes the share page
`../site/survey/index.html`).

- `PRE-ANALYSIS-PLAN.md`: the pre-analysis plan, the source of truth, registered on the AEA RCT
  Registry (trial 19997) on 2026-10-19. Section 9, "How to launch", is the launch sequence;
  section 11 lists the decisions taken.
- `plan/`: the plan as a PDF. `build.sh` turns the markdown into `plan-body.tex`, wraps it in
  `plan.tex` and makes `plan.pdf`. `plan/forms/` holds the control and treatment forms as Google
  Forms served them (`control.json`, `treatment.json`); `print_forms.py` prints them to
  `control.pdf` and `treatment.pdf`, the plan's Appendix B.
- `power/`: the appendix on power, `power.pdf` from `power.tex`. `sim.py` generates every number
  in it into `out/`; `explore/` is a side calculation that is not registered.
- `mock_forms.py`: the wording of every question, the treatment page and the form's description,
  with every number read from `../export/r/`; it writes HTML previews of the two forms.
- `gas_build.py`: writes the Google Apps Script that built the six forms as copies of the version
  1 form (`buildExperiment()`) and later edited them in place (`fixEnding()`, `moveEmail()`,
  `fixPrior()`, whose log lists each form's links, and `inputsIntro()`, the inputs section's
  text in both arms, set by hand on 2026-10-19).
- `fill_links.py`: fills `../data/survey-links.csv` from that log (`--out PATH` writes a scratch
  copy first). It refuses a log that lacks a form, has two copies of one, or shows one unfinished.
- `draws.gs`: the draw count's web app, one row (timestamp, entry point, arm) per click on a
  survey link; its header says how to deploy it.
- `pilot_text.py`, `pilot_harvest.py`, `pilot_transcripts.py`: the two pretests with simulated
  respondents (`../../feedback/008-2026-10-17-rct-pilot/` and `009-2026-10-17-rct-pilot-2/`).
- `pilot_analysis.py`: the registered analysis (plan, section 9: its version at the launch commit
  is the registered one). It reads the four forms' sheet exports, or a pretest's file, applies the
  rules of section 8 (the window, email duplicates, bulk submissions), runs the attrition checks,
  H1, S1 and S2, and each staged family once N reaches its threshold in `power/out/thresholds.tex`.
  `check_pilot_analysis.py` checks every path of it. Its run on the second pretest is in
  `../../feedback/011-2026-10-18-pap-review/pilot2-registered-run/`.
- `registry-draft.md`: the fields entered in the registry's draft.

Each of forms 3 to 6 is linked to a responses spreadsheet at launch (plan, section 9, step 7).
The control forms' A and B are mapped to the two studies in the plan, section 5.1. After the
close, the responses are published in the repository without the email column and the free-text
answers (plan, section 9).
