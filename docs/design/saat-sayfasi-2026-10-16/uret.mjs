// Saat sayfası taslaklarını üretir: kaynak/ → secenek-*.html (tek dosya) ve png/.
// Kullanım: node uret.mjs   (önceden kurulu Chromium + Playwright ile)
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const src = (f) => readFileSync(join(here, 'kaynak', f), 'utf8');
const css = src('ortak.css');
const js = src('ortak.js');

const page = (title, extraCss, body, script) => `<!doctype html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title><style>${css}${extraCss}</style></head>
<body><div id="root"></div><script>${js}\n${script}</script>${body}</body></html>`;

const options = ['a', 'b', 'c'];
for (const o of options) {
  const opt = src(`secenek-${o}.js`);
  const m = opt.match(/name: '([^']+)'/);
  // css alanı ayrıca <style>'a da konur, mount() çağrılır.
  writeFileSync(join(here, `secenek-${o}.html`), page(m[1], '',
    '', `${opt}\ndocument.head.insertAdjacentHTML('beforeend', '<style>' + OPTION.css + '</style>');\nmount(OPTION);`));
}

// Alt menü 320 pt karşılaştırması: "Hava Durumu" ile "Hava".
writeFileSync(join(here, 'alt-menu-320.html'), page('Alt menü 320 pt', `
  .cmp{display:flex;flex-direction:column;gap:18px;padding:20px 0;background:#0B1620;width:320px}
  .cmp p{font-size:13px;color:#9CB1C0;padding:0 14px}`, '', `
  const long = { ...NAV_LABELS, environment: 'Hava Durumu' };
  document.getElementById('root').innerHTML = '<div class="cmp">' +
    '<p>Bugünkü etiketle (Hava Durumu): 6 düğmede yazı sığmaz, küçülür</p><div style="width:320px">' + nav('watch', long) + '</div>' +
    '<p>Önerilen: Hava</p><div style="width:320px">' + nav('watch') + '</div></div>';
  // FittedBox(scaleDown) davranışı: sığmayan etiket küçülür.
  document.querySelectorAll('.nav .it b').forEach((b) => {
    const avail = b.parentElement.clientWidth - 4; const need = b.scrollWidth;
    if (need > avail) b.style.transform = 'scale(' + (avail / need).toFixed(3) + ')';
  });`));

// ---------- ekran görüntüleri ----------
const shots = [];
for (const o of options) {
  for (const s of [1, '1b', 2, 3, 4]) shots.push({ f: `secenek-${o}.html`, q: `s=${s}&w=390`, out: `${o}-${s}.png`, w: 390 });
  shots.push({ f: `secenek-${o}.html`, q: 's=3&w=320', out: `${o}-320.png`, w: 320 });
  const info = { a: 'garmin', b: 'apple', c: 'gorunen' }[o];
  shots.push({ f: `secenek-${o}.html`, q: `s=2&w=390&info=${info}`, out: `${o}-bilgi.png`, w: 390, fixed: true });
}
mkdirSync(join(here, 'png'), { recursive: true });
const browser = await chromium.launch();
const ctx = await browser.newContext({ deviceScaleFactor: 2 });
const pg = await ctx.newPage();
for (const s of shots) {
  await pg.setViewportSize({ width: s.w, height: 844 });
  await pg.goto(pathToFileURL(join(here, s.f)).href + '?' + s.q);
  await pg.evaluate(() => document.fonts.ready);
  const el = await pg.$('.phone');
  if (s.fixed) {
    // ⓘ alt sayfası: tam 844 yükseklikte telefon, sayfa altta karartılmış.
    await pg.$eval('.phone', (p) => { p.style.height = '844px'; });
  }
  await el.screenshot({ path: join(here, 'png', s.out) });
  console.log('png/' + s.out);
}
await pg.setViewportSize({ width: 320, height: 400 });
await pg.goto(pathToFileURL(join(here, 'alt-menu-320.html')).href);
await (await pg.$('.cmp')).screenshot({ path: join(here, 'png', 'alt-menu-320.png') });
console.log('png/alt-menu-320.png');

// Yan yana galeri görüntüsü (PR açıklaması için).
await pg.setViewportSize({ width: 1340, height: 900 });
await pg.goto(pathToFileURL(join(here, 'index.html')).href + '?shot=1');
await pg.waitForLoadState('load');
await (await pg.$('#yanyana')).screenshot({ path: join(here, 'png', 'yan-yana.png') });
console.log('png/yan-yana.png');
await browser.close();
