// Seçenek C — Önce durum: canlı saat önizlemesi + tek gönderim düğmesi.
const OPTION = {
  name: 'Seçenek C — Önce durum ve önizleme',
  idea: 'Sayfanın tepesinde saatin şu an ne gösterdiği durur: gerçek saat yüzü, altında durum ve tek gönderim düğmesi. “Saatte görünenler”de bir bilgiyi kapatınca önizlemeden de kalkar. Saatler ve ayarlar aşağıda.',
  infoExample: 'gorunen',
  css: `
  .hero { padding:14px 14px 14px; position:relative }
  .hero .faces { display:flex; justify-content:center; align-items:center; gap:12px; padding:4px 0 14px }
  .hero .tag { position:absolute; left:14px; top:14px; height:24px; padding:0 10px; border-radius:999px;
               border:1px solid var(--line); background:var(--bg); font-size:12.5px; color:var(--ink2); display:flex; align-items:center }
  .hero h3 { font-family:var(--font-d); font-size:22px; font-weight:700; line-height:1.15 }
  .hero .sub { font-size:14px; line-height:1.4; color:var(--ink2); margin:4px 0 12px }
  .hero .row2 .lab { height:32px }
  `,
  render(st, w) {
    const conn = isConnected(st);
    const live = st.watches.filter((x) => !x.pending);
    const two = live.length > 1;
    const narrow = w < 360;
    const brand = st.brand || 'Garmin';
    const fs = two ? (narrow ? 7.4 : 8.8) : (narrow ? 10.5 : 12);
    const stale = st.send === 'fail';
    const faces = conn
      ? live.map((x) => face(x.brand === 'Garmin' ? 'round' : 'rect', st.off, { size: fs, stale: stale && x.fail })).join('')
      : face(brand === 'Apple Watch' ? 'rect' : 'round', [], { size: fs });
    const pick = (label) => `<div class="hint">${connectHint(brand)}</div><div class="row2">${field('Saat markası', brand)}${btn(label)}</div>`;
    let head, sub, action = '';
    if (st.watches.length === 0) {
      head = 'Saatinizi bağlayın';
      sub = 'Kule klikleriniz her hesapta saatinizde bu yüzdeki gibi görünür. Markayı seçip “Saati bağla”ya dokunun.';
      action = pick('Saati bağla');
    } else if (!conn) {
      head = 'Apple Watch bekleniyor';
      sub = 'Saatte SNIPER TÜRK\'ü bir kez açın. Bağlanınca son hesap hemen saate gider.';
    } else if (st.send === 'ok') {
      head = two ? '2 saat bağlı' : 'Fenix 7 bağlı';
      sub = `Son hesap 14:32'de ${two ? 'iki saate' : 'saate'} gitti. Her yeni hesap kendiliğinden gider.`;
      action = btn('Hesap saate gönderildi', 'done');
    } else {
      head = 'Fenix 7\'ye gönderilemedi';
      sub = 'Fenix 7 14:20\'deki eski hesabı gösteriyor. Saati telefona yaklaştırıp tekrar gönderin.';
      action = btn('Hesabı saate gönder');
    }
    let html = card(`${conn ? '' : '<span class="tag">Örnek</span>'}<div class="faces">${faces}</div><h3>${head}</h3><div class="sub">${sub}</div>${action}`, `hero${stale ? ' warn' : ''}`);
    if (st.watches.length === 0) return html;
    html += sectionHeader('Saatler', 'isteğe bağlı');
    const rows = st.watches.map((x) => watchRow(x)).join('');
    if (!conn) return html + card(rows);
    html += card(rows + `<div style="border-top:1px solid var(--line);margin-top:2px;padding-top:4px">${pick('Başka saat bağla')}</div>`);
    html += sectionHeader('Saatte görünenler') + card(chips(st.off));
    html += sectionHeader('Saatten gelenler') + card(recvTiles(st.recv));
    return html;
  },
};
