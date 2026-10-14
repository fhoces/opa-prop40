#!/usr/bin/env node
// A page rendered by a headless browser: a screenshot, or its text after the page's script has
// run. Needs Playwright (the cloud container has it at /opt/node-tools; locally, `npm i -g
// playwright` and `npx playwright install chromium`). Exits 2 with a message if it is missing.
//
//   node screenshot.cjs <file.html|url> [--out shot.png] [--width 390|1280] [--full] [--text]
//                       [--click "<css selector>"]... [--select "<css selector>=<value>"]...
//                       [--wait ms]
//
// --text prints document.body.innerText (the rendered text, numbers filled by script included).
// --click presses a control before the capture (a dial, a tab); --select sets a <select> or an
// <input type=range>; both can repeat and run in the order given.
const path = require('path');
const fs = require('fs');
const os = require('os');
const { execSync } = require('child_process');

function loadPlaywright() {
  const tries = ['playwright', '/opt/node-tools/node_modules/playwright'];
  try { tries.push(path.join(execSync('npm root -g', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(), 'playwright')); } catch (e) {}
  for (const t of tries) { try { return require(t); } catch (e) {} }
  console.error('Playwright is not installed: skip screenshots (read the page as text instead).');
  process.exit(2);
}

const args = process.argv.slice(2);
if (!args.length || args[0].startsWith('--')) {
  console.error('usage: node screenshot.cjs <file.html|url> [--out png] [--width n] [--full] [--text] [--click sel] [--select sel=value] [--wait ms]');
  process.exit(1);
}
let target = args[0];
const opt = { width: 1280, full: false, text: false, out: null, clicks: [], selects: [], wait: 300 };
for (let i = 1; i < args.length; i++) {
  const a = args[i];
  if (a === '--out') opt.out = args[++i];
  else if (a === '--width') opt.width = parseInt(args[++i], 10);
  else if (a === '--full') opt.full = true;
  else if (a === '--text') opt.text = true;
  else if (a === '--click') opt.clicks.push(args[++i]);
  else if (a === '--select') opt.selects.push(args[++i]);
  else if (a === '--wait') opt.wait = parseInt(args[++i], 10);
  else { console.error('unknown option ' + a); process.exit(1); }
}
if (!/^https?:\/\//.test(target)) target = 'file://' + path.resolve(target);
if (!opt.text && !opt.out) {
  const dir = path.join(os.tmpdir(), 'opa-review-loop');
  fs.mkdirSync(dir, { recursive: true });
  const base = path.basename(target.replace(/\/index\.html$/, '')).replace(/[^\w.-]+/g, '_') || 'page';
  opt.out = path.join(dir, `${base}-${opt.width}.png`);
}

(async () => {
  const { chromium } = loadPlaywright();
  const browser = await chromium.launch();
  const height = opt.width < 600 ? 844 : 800;
  const page = await browser.newPage({ viewport: { width: opt.width, height } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto(target, { waitUntil: 'load' });
  await page.waitForTimeout(opt.wait);
  for (const s of opt.selects) {
    const k = s.indexOf('=');
    const sel = s.slice(0, k), val = s.slice(k + 1);
    const tag = await page.$eval(sel, el => el.tagName.toLowerCase());
    if (tag === 'select') await page.selectOption(sel, val);
    else await page.$eval(sel, (el, v) => { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true })); }, val);
    await page.waitForTimeout(150);
  }
  for (const c of opt.clicks) { await page.click(c); await page.waitForTimeout(150); }
  if (opt.text) {
    const t = await page.evaluate(() => document.body.innerText);
    process.stdout.write(t.replace(/\n{3,}/g, '\n\n') + '\n');
  }
  if (opt.out) {
    await page.screenshot({ path: opt.out, fullPage: opt.full });
    console.error('screenshot: ' + opt.out);
  }
  if (errors.length) console.error('page errors: ' + errors.join(' | '));
  await browser.close();
})().catch(e => { console.error('error: ' + e.message); process.exit(1); });
