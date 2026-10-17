/**
 * The draw count of the Prop 40 survey experiment (comparison/survey/PRE-ANALYSIS-PLAN.md,
 * section 8, item 3). Every survey link on the site sends one request at the draw:
 *   <web app URL>?entry=landing|explorer|share&arm=control|treatment
 * This web app appends one row (timestamp, entry, arm) to the sheet below. The request carries
 * nothing else: no identifier, no cookie.
 *
 * The pages send the request with navigator.sendBeacon, which is always a POST, so doPost does
 * the work; doGet does the same, so the address can be tested by opening it in a browser.
 *
 * How to deploy (once):
 *   1. Make a new Google Sheet for the counts (or a new tab in the responses sheet) and copy its
 *      id, the part of its address between /d/ and /edit. Paste it into SHEET_ID below. Set
 *      TAB to the tab's name.
 *   2. Make a new Apps Script project (script.google.com, New project), paste this file into
 *      Code.gs and save.
 *   3. Deploy > New deployment > type "Web app". Execute as: Me. Who has access: Anyone.
 *      Deploy, and allow the access it asks for (it writes to the sheet).
 *   4. Copy the web app URL (it ends in /exec). Test it once by opening
 *      <URL>?entry=test&arm=test in a browser: the reply is "ok" and the sheet gets a row.
 *      Delete that row.
 *   5. Paste the URL into comparison/data/survey-config.csv as the value of draws_url, then
 *      rebuild the site (Rscript comparison/run.R). With draws_url empty the pages send nothing.
 * A later edit to this script needs Deploy > Manage deployments > edit > New version, which
 * keeps the same URL.
 */
var SHEET_ID = "PASTE_THE_SHEET_ID_HERE";
var TAB = "Draws";
var ENTRIES = ["landing", "explorer", "share", "test"];
var ARMS = ["control", "treatment", "test"];

function record_(e) {
  var p = (e && e.parameter) || {};
  var entry = String(p.entry || ""), arm = String(p.arm || "");
  // Only the expected values are written, so a stray request cannot put text into the sheet.
  if (ENTRIES.indexOf(entry) < 0 || ARMS.indexOf(arm) < 0) {
    return ContentService.createTextOutput("ignored").setMimeType(ContentService.MimeType.TEXT);
  }
  var lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    var book = SpreadsheetApp.openById(SHEET_ID);
    var sheet = book.getSheetByName(TAB) || book.insertSheet(TAB);
    if (sheet.getLastRow() === 0) sheet.appendRow(["timestamp", "entry", "arm"]);
    sheet.appendRow([new Date(), entry, arm]);
  } finally {
    lock.releaseLock();
  }
  return ContentService.createTextOutput("ok").setMimeType(ContentService.MimeType.TEXT);
}

function doPost(e) { return record_(e); }
function doGet(e) { return record_(e); }
