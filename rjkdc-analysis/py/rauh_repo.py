"""Single resolver for the authors' MIT-licensed repo. Python twin of
R/rauh_repo.R - same env var, same default, same file layout."""
import os

DEFAULT_RAUH_REPO_DIR = "original-materials/author-shared/2026-09-23_wealth_tax-repo"


def rauh_repo_dir():
    return os.environ.get("RAUH_REPO_DIR", DEFAULT_RAUH_REPO_DIR)


def rauh_path(*parts):
    return os.path.join(rauh_repo_dir(), *parts)


def rauh_available():
    return os.path.isdir(rauh_repo_dir())


def rauh_workbook_path():
    return rauh_path("NPV_data", "CA_Billionaires_Revenues_and_Migration_final.xlsx")


def rauh_nber_final_csv():
    return rauh_path("NBER_2026_litigation_weighted", "NPV_data", "final.csv")
