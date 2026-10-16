// SNIPER TÜRK — Saat sayfası taslakları: ortak parçalar.
// Her parça lib/ui/menzil_widgets.dart'taki karşılığını taklit eder.
// Değerler örnektir; hiçbir hesaptan gelmez.

const SVG = (inner, vb = '0 0 24 24') =>
  `<svg viewBox="${vb}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`;

// lib/ui/menzil_icons.dart çizimlerinin SVG karşılığı + yeni "saat" glifi.
const GLYPH = {
  profile: SVG('<path d="M9 21V10C9 7 10.2 4.5 12 3C13.8 4.5 15 7 15 10V21"/><path d="M9 21H15M9 14H15"/>'),
  environment: SVG('<path d="M3 9H14A3 3 0 1 0 11 6"/><path d="M3 14H18A3 3 0 1 1 15 17"/><path d="M3 19H10"/>'),
  pro: SVG('<path d="M3 20H21M3 20L17 5"/><path d="M8.46 14.15A8 8 0 0 1 11 20"/><circle cx="19" cy="11.5" r="1.6"/>'),
  shot: SVG('<circle cx="12" cy="12" r="7"/><path d="M12 2V7M12 17V22M2 12H7M17 12H22"/>'),
  // Yeni: Saat. Aynı 24'lük ızgara, 2 pt çizgi; kasa + kayış + akrep/yelkovan.
  watch: SVG('<rect x="6.5" y="6" width="11" height="12" rx="3"/><path d="M9 6L9.6 2.5H14.4L15 6M9 18L9.6 21.5H14.4L15 18"/><path d="M12 9.5V12L13.8 13"/>'),
  tools: SVG('<path d="M4 7H13M17 7H20M4 17H7M11 17H20"/><circle cx="15" cy="7" r="2.2"/><circle cx="9" cy="17" r="2.2"/>'),
};
const ICON = {
  info: SVG('<circle cx="12" cy="12" r="9.5" stroke-width="1.8"/><path d="M12 11V16.5" stroke-width="1.8"/><circle cx="12" cy="7.6" r=".6" fill="currentColor" stroke-width="1.2"/>'),
  chevron: SVG('<path d="M7 10L12 15L17 10"/>'),
  check: SVG('<path d="M5 12.5L10 17L19 7.5"/>'),
  checkBold: SVG('<path d="M5 12.5L10 17L19 7.5" stroke-width="3.2"/>'),
  lockBold: SVG('<rect x="6" y="11" width="12" height="9" rx="1.5" fill="currentColor" stroke-width="2"/><path d="M8.5 11V8.5a3.5 3.5 0 0 1 7 0V11" stroke-width="2.6"/>'),
  lock: SVG('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'),
};

const NAV_LABELS = { profile: 'Profil', environment: 'Hava', pro: 'Pro', shot: 'Hedef', watch: 'Saat', tools: 'Araçlar' };

// ---------- örnek durumlar ----------
const GARMIN = { brand: 'Garmin', name: 'Fenix 7', last: '14:32' };
const APPLE = { brand: 'Apple Watch', name: 'Apple Watch', last: '14:32' };
// Kapalı çipler (2–4. durumlarda kullanıcı ikisini kapatmış gibi gösterilir).
const OFF_LATER = ['dir', 'clock'];
const STATES = {
  1: { key: 1, title: 'İlk açılış, saat yok', watches: [], send: null, recv: null, off: [] },
  2: { key: 2, title: 'Bir Garmin bağlı, gönderildi', watches: [GARMIN], send: 'ok', off: OFF_LATER,
       recv: { range: '600 m', rangeAt: '14:31', angle: null } },
  3: { key: 3, title: 'Garmin + Apple Watch bağlı', watches: [GARMIN, APPLE], send: 'ok', off: OFF_LATER,
       recv: { range: '600 m', rangeAt: '14:31', angle: '−4°', angleAt: '14:31' } },
  4: { key: 4, title: 'Gönderilemedi', send: 'fail', off: OFF_LATER,
       watches: [{ ...GARMIN, fail: true, last: '14:20' }, { ...APPLE, last: '14:32' }],
       recv: { range: '600 m', rangeAt: '14:31', angle: '−4°', angleAt: '14:31' } },
};

// Saatte görünenler: 10 bilgi, ilk ikisi kilitli (her zaman açık).
const FIELDS = [
  { id: 'clicks', label: 'Kule klikleri', lock: true },
  { id: 'range', label: 'Mesafe', lock: true },
  { id: 'profile', label: 'Profil adı' },
  { id: 'angle', label: 'Açı değeri' },
  { id: 'wind', label: 'Rüzgâr hızı' },
  { id: 'dir', label: 'Rüzgâr yönü' },
  { id: 'click', label: 'Klik değeri' },
  { id: 'calc', label: 'Hesap saati' },
  { id: 'clock', label: 'Günün saati' },
  { id: 'stale', label: 'Eski veri uyarısı', short: 'Eski veri' },
];

// ---------- ⓘ metinleri (kısa Türkçe: ne, nerede, örnek) ----------
const NO_CHANGE = 'Saati kullanmazsanız hiçbir ayarınız ve hesabınız değişmez.';
const INFO = {
  saatler: {
    title: 'Saatler',
    body: [`Hesabın sonucunu bileğinizdeki saatte gösterir. Garmin ve Apple Watch aynı anda bağlanabilir. Örnek: Fenix 7 · bağlı.`, NO_CHANGE],
  },
  marka: {
    title: 'Saat markası',
    body: [`Bağlayacağınız saatin markası. Saatin kutusunda ya da arkasında yazar. Örnek: Fenix 7 için Garmin.`, NO_CHANGE],
  },
  garmin: {
    title: 'Garmin saati bağlama',
    steps: [
      'Saate Connect IQ mağazasından SNIPER TÜRK uygulamasını yükleyin.',
      'Saat markası olarak Garmin seçip “Saati bağla”ya dokunun; Garmin Connect açılır.',
      'Garmin Connect\'te saatinizi seçin ve buraya dönün. Örnek: listede Fenix 7 · bağlı yazar.',
    ],
    body: ['Telefonda Garmin Connect yüklü ve saat telefonla eşli olmalı. ' + NO_CHANGE],
  },
  apple: {
    title: 'Apple Watch bağlama',
    steps: [
      'SNIPER TÜRK iPhone\'a yüklenince saat uygulaması da kendiliğinden gelir.',
      'Saatte SNIPER TÜRK\'ü bir kez açın.',
      'Buraya dönün. Örnek: listede Apple Watch · bağlı yazar.',
    ],
    body: ['Saat iPhone ile eşli ve yakında olmalı. ' + NO_CHANGE],
  },
  gonder: {
    title: 'Saate gönderim',
    body: ['Her yeni hesapta sonuç bağlı saatlere kendiliğinden gider. Gönderilemezse düğme “Hesabı saate gönder” olur; dokunup tekrar gönderin. Örnek: saat telefondan uzaksa gönderim olmaz.'],
  },
  gorunen: {
    title: 'Saatte görünenler',
    body: ['Saat ekranında hangi bilgilerin görüneceğini seçer. Kule klikleri ve Mesafe hep görünür; diğerlerine dokunup açın ya da kapatın. Seçim bağlı bütün saatlere uygulanır. Örnek: Rüzgâr yönü kapalıysa saatte yalnız “Rüzgâr 3.0 m/s” yazar.'],
  },
  gelen: {
    title: 'Saatten gelenler',
    body: ['Saatte değiştirdiğiniz mesafe ve saatin terazisiyle ölçtüğünüz atış açısı buraya gelir; hesap bunlarla yenilenir ve sonuç saate geri gider. Örnek: saatte mesafeyi 600 m yaptınız; burada Mesafe 600 m, 14:31 yazar.', NO_CHANGE],
  },
};

// ---------- parçalar ----------
const esc = (s) => String(s);
const ib = () => `<span class="ib" aria-label="Bilgi">${ICON.info}</span>`;

function statusbar() {
  return `<div class="statusbar"><span>14:33</span><span class="batt"><i></i></span></div>`;
}
function topbar(title = 'Saat') {
  return `<div class="topbar"><h1>${title}</h1><div class="profile-pill"><span>Tikka T3x .308</span>${ICON.chevron}</div></div>`;
}
function nav(active = 'watch', labels = NAV_LABELS) {
  const order = ['profile', 'environment', 'pro', 'shot', 'watch', 'tools'];
  return `<nav class="nav">${order.map((k) =>
    `<div class="it${k === active ? ' on' : ''}">${GLYPH[k]}<b>${labels[k]}</b></div>`).join('')}</nav>`;
}
function sectionHeader(title, end = '') {
  return `<div class="sh"><h2>${title}</h2>${ib()}${end ? `<span class="end">${end}</span>` : ''}</div>`;
}
const card = (html, cls = '') => `<div class="card ${cls}">${html}</div>`;
function field(label, value, { info = true } = {}) {
  return `<div class="fld"><div class="lab">${label}${info ? ib() : ''}</div><div class="box"><span>${value}</span>${ICON.chevron}</div></div>`;
}
// Düğme rolleri: out = eylem, done = tamam (✓), white = sayfa geçişi / Kapat.
function btn(label, role = 'out', extra = '') {
  const tick = role === 'done' ? ICON.check : '';
  return `<div class="btn ${role} ${extra}">${tick}<span>${label}</span></div>`;
}
function dateRow(text) { return `<div class="daterow">${text}</div>`; }
function notice(title, text) { return `<div class="notice"><b>${title}</b>${text}</div>`; }

function watchRow(w, { remove = true } = {}) {
  const st = w.fail ? '<span class="st bad"> · yanıt yok</span>' : '<span class="st"> · bağlı</span>';
  const sub = (w.brand !== w.name ? `${w.brand} · ` : '') + `son gönderim ${w.last}`;
  return `<div class="wrow"><div class="wglyph">${GLYPH.watch}</div>
    <div class="wtxt"><div class="n">${w.name}${st}</div><div class="s">${sub}</div></div>
    ${remove ? btn('Kaldır', 'out', 'small') : ''}</div>`;
}

function chip(f, off) {
  const name = f.short ? `<b class="full">${f.label}</b><b class="short">${f.short}</b>` : f.label;
  if (f.lock) return `<div class="chip lock" aria-label="${f.label}, her zaman açık"><span class="dot">${ICON.lockBold}</span><span>${f.label}</span></div>`;
  const isOff = off.includes(f.id);
  return isOff
    ? `<div class="chip off" aria-label="${f.label}, kapalı"><span class="dot"></span><span>${name}</span></div>`
    : `<div class="chip on" aria-label="${f.label}, açık"><span class="dot">${ICON.checkBold}</span><span>${name}</span></div>`;
}
const chips = (off) => `<div class="chips">${FIELDS.map((f) => chip(f, off)).join('')}</div>`;

function recvTiles(r) {
  const t = (k, v, at) => `<div class="rtile"><div class="k">${k}</div>
    <div class="v${v ? '' : ' empty'}">${v || '—'}</div><div class="t">${v ? 'Saatten, ' + at : 'Henüz gelmedi'}</div></div>`;
  return `<div class="recv">${t('Mesafe', r && r.range, r && r.rangeAt)}${t('Atış açısı', r && r.angle, r && r.angleAt)}</div>`;
}

// Saat yüzü önizlemesi: docs/saat-uygulamasi/taslak'taki ekranların küçük hali.
// "off" listesindeki bilgiler yüzde görünmez.
function face(kind, off = [], { size = 13, stale = false } = {}) {
  const on = (id) => !off.includes(id);
  const wind = on('wind') ? `Rüzgâr 3.0 m/s${on('dir') ? ' · saat 3' : ''}` : (on('dir') ? 'Rüzgâr saat 3' : '');
  const lines = [wind, on('click') ? 'MRAD · 0.1/klik' : '', on('calc') ? `Güncellendi ${stale ? '14:20' : '14:32'}` : ''].filter(Boolean);
  const dim = kind === 'round' ? `width:16em;height:16em` : `width:13.4em;height:16em`;
  return `<div class="face ${kind}${stale ? ' stale' : ''}" style="font-size:${size}px;${dim}">
    ${on('clock') ? '<div class="tm">14:33</div>' : ''}
    ${on('profile') ? '<div class="pr">Tikka T3x .308</div>' : ''}
    <div class="rg">600 m</div>
    <div class="cl"><div><span class="lb">Yukarı</span><span class="num up">↑47</span>${on('angle') ? '<span class="an">4.7 MRAD</span>' : ''}</div>
    <span class="sep"></span>
    <div><span class="lb">Sağ</span><span class="num">→6</span>${on('angle') ? '<span class="an">0.6 MRAD</span>' : ''}</div></div>
    <div class="ft">${lines.join('<br>')}</div></div>`;
}

function infoSheet(key) {
  const i = INFO[key];
  const steps = i.steps ? `<ol>${i.steps.map((s) => `<li><span>${s}</span></li>`).join('')}</ol>` : '';
  return `<div class="scrim"></div><div class="sheet"><div class="handle"></div><h3>${i.title}</h3>
    ${steps}${(i.body || []).map((p) => `<p>${p}</p>`).join('')}${btn('Kapat', 'white')}</div>`;
}

function phone(bodyHtml, { w = 390, overlay = '' } = {}) {
  return `<div class="phone${w < 360 ? ' tight' : ''}" style="--w:${w}px">${statusbar()}${topbar()}<main class="page">${bodyHtml}</main>${nav()}${overlay}</div>`;
}

// ?s=1..4  (durum)  &w=390|320  &info=anahtar (o durumun üstünde ⓘ alt sayfası)
// Parametresiz: bütün durumlar yan yana (galeri).
function mount(option) {
  const q = new URLSearchParams(location.search);
  const root = document.getElementById('root');
  if (q.has('s')) {
    const st = STATES[q.get('s')];
    const w = Number(q.get('w') || 390);
    const overlay = q.get('info') ? infoSheet(q.get('info')) : '';
    root.innerHTML = phone(option.render(st, w), { w, overlay });
    document.body.style.background = '#0B1620';
    return;
  }
  const figs = [1, 2, 3, 4].map((k) =>
    `<figure>${phone(option.render(STATES[k], 390))}<figcaption>${k}. ${STATES[k].title}</figcaption></figure>`).join('');
  const narrow = `<figure>${phone(option.render(STATES[3], 320), { w: 320 })}<figcaption>320 pt denetimi (3. durum)</figcaption></figure>`;
  const sheet = `<figure>${phone(option.render(STATES[2], 390), { overlay: infoSheet(option.infoExample) })}<figcaption>ⓘ alt sayfası: ${INFO[option.infoExample].title}</figcaption></figure>`;
  root.innerHTML = `<div class="gallery"><header><h1>${option.name}</h1><p>${option.idea}</p></header>${figs}${narrow}${sheet}</div>`;
}
