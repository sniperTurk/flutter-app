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
    const has = st.watches.length > 0;
    const two = st.watches.length > 1;
    const narrow = w < 360;
    const fs = two ? (narrow ? 7.4 : 8.8) : (narrow ? 10.5 : 12);
    const stale = st.send === 'fail';
    let faces;
    if (!has) faces = face('round', [], { size: fs });
    else faces = st.watches.map((x) => face(x.brand === 'Garmin' ? 'round' : 'rect', st.off, { size: fs, stale: stale && x.fail })).join('');
    let head, sub, action;
    if (!has) {
      head = 'Saat bağlı değil';
      sub = 'Bağlayınca kule klikleri her hesapta bu yüzdeki gibi saatinize gider.';
      action = `<div class="row2">${field('Saat markası', 'Garmin')}${btn('Saati bağla')}</div>`;
    } else if (st.send === 'ok') {
      head = two ? '2 saat bağlı' : 'Fenix 7 bağlı';
      sub = `Son hesap 14:32'de ${two ? 'iki saate' : 'saate'} gitti.`;
      action = btn('Hesap saate gönderildi', 'done');
    } else {
      head = 'Fenix 7\'ye gönderilemedi';
      sub = 'Fenix 7 14:20\'deki eski hesabı gösteriyor. Saati telefona yaklaştırıp tekrar gönderin.';
      action = btn('Hesabı saate gönder');
    }
    let html = card(`${has ? '' : '<span class="tag">Örnek</span>'}<div class="faces">${faces}</div><h3>${head}</h3><div class="sub">${sub}</div>${action}`, `hero${stale ? ' warn' : ''}`);
    if (has) {
      html += sectionHeader('Saatler', 'isteğe bağlı');
      html += card(st.watches.map((x) => watchRow(x)).join('') +
        `<div style="border-top:1px solid var(--line);margin-top:2px;padding-top:2px"><div class="row2">${field('Saat markası', 'Garmin')}${btn('Başka saat bağla')}</div></div>`);
    }
    html += sectionHeader('Saatte görünenler') + card(chips(st.off));
    html += sectionHeader('Saatten gelenler') + card(recvTiles(st.recv));
    return html;
  },
};
