// Seçenek B — Önce saat listesi; boşken satın almaya teşvik eden tanıtım.
const OPTION = {
  name: 'Seçenek B — Önce saat listesi',
  idea: 'Sayfa bağlı saatlerin listesiyle başlar; her saat kendi kartında, sorun o saatin kartında görünür. Saat yokken iki saat yüzü “ne kazanırsınız”ı gösterir; ayarlar ilk saat bağlanınca açılır.',
  infoExample: 'apple',
  css: `
  .promo { display:flex; flex-direction:column; gap:12px }
  .promo .faces { display:flex; justify-content:center; align-items:center; gap:14px; padding:6px 0 2px }
  .promo h3 { font-family:var(--font-d); font-size:20px; font-weight:700; line-height:1.15 }
  .promo p { font-size:14px; line-height:1.4; color:var(--ink2); margin-top:-6px }
  .brands { display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:10px }
  .brand { height:64px; border-radius:var(--r-button); border:1px solid var(--line); background:var(--surface);
           display:flex; align-items:center; gap:10px; padding:0 12px; font-size:15px; font-weight:600; min-width:0 }
  .brand span { flex:1; min-width:0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis }
  .brand .radio { width:22px; height:22px; flex:none; border-radius:50%; border:2px solid var(--ink2) }
  .brand.sel { border:2px solid var(--cyan); background:var(--cyan-soft) }
  .brand.sel .radio { border-color:var(--cyan); background:radial-gradient(circle, var(--cyan) 0 5px, transparent 5.5px) }
  .wcard { padding:4px 14px }
  .wcard .inline { margin:0 0 12px }
  .wcard .inline .notice { margin-top:0 }
  `,
  render(st, w) {
    const conn = isConnected(st);
    const brand = st.brand || 'Garmin';
    const fs = w < 360 ? 7.6 : 9;
    const tiles = `<div class="brands"><div class="brand${brand === 'Garmin' ? ' sel' : ''}"><i class="radio"></i><span>Garmin</span></div>
        <div class="brand${brand === 'Apple Watch' ? ' sel' : ''}"><i class="radio"></i><span>Apple Watch</span></div></div>`;
    if (st.watches.length === 0) {
      let html = card(`<div class="promo"><div class="faces">${face('round', [], { size: fs })}${face('rect', [], { size: fs })}</div>
        <h3>Klikler bileğinizde</h3>
        <p>Her hesap saatinize kendiliğinden gider. Başlamak için aşağıdan saatinizin markasını seçip “Saati bağla”ya dokunun.</p></div>`);
      html += sectionHeader('Saat markası', 'isteğe bağlı') + tiles;
      html += `<div class="hint" style="margin:0 0 8px">${connectHint(brand)}</div>` + btn('Saati bağla');
      return html;
    }
    let html = sectionHeader('Saatlerim', 'isteğe bağlı');
    for (const x of st.watches) {
      const warn = x.fail ? notice('Gönderilemedi', 'Saat telefondan uzakta ya da saatte SNIPER TÜRK kapalı. Saati yaklaştırıp “Hesabı saate gönder”e dokunun.') : '';
      html += card(watchRow(x) + (warn ? `<div class="inline">${warn}</div>` : ''), 'wcard');
    }
    if (!conn) return html;
    html += st.send === 'ok'
      ? btn('Hesap saate gönderildi', 'done') + dateRow('Her yeni hesap kendiliğinden gider · son 14:32')
      : btn('Hesabı saate gönder') + dateRow('Son başarılı gönderim 14:32 · Apple Watch');
    html += sectionHeader('Başka saat bağla') + tiles;
    html += `<div class="hint" style="margin:0 0 8px">${connectHint(brand)}</div>` + btn('Saati bağla');
    html += `<div style="height:10px"></div>`;
    html += sectionHeader('Saatte görünenler') + card(chips(st.off));
    html += sectionHeader('Saatten gelenler') + card(recvTiles(st.recv));
    return html;
  },
};
