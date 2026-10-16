// Seçenek A — Bölüm kartları (Hava Durumu düzeni).
const OPTION = {
  name: 'Seçenek A — Bölüm kartları',
  idea: 'Hava Durumu sayfasının düzeni: başlık + ⓘ, altında kart. Saatler, Saate gönderim, Saatte görünenler, Saatten gelenler sırayla. Saat markası ile “Saati bağla” Basınç Ölçer gibi aynı satırda.',
  infoExample: 'garmin',
  css: '',
  render(st, w) {
    const has = st.watches.length > 0;
    const rows = st.watches.map((x) => watchRow(x)).join('');
    const pick = `<div class="row2">${field('Saat markası', 'Garmin')}${btn(has ? 'Başka saat bağla' : 'Saati bağla')}</div>`;
    let html = sectionHeader('Saatler', 'isteğe bağlı');
    html += card(has ? `${rows}<div style="border-top:1px solid var(--line);margin-top:2px;padding-top:2px">${pick}</div>` : pick);
    if (has) {
      html += sectionHeader('Saate gönderim');
      const n = st.watches.length;
      html += card(st.send === 'ok'
        ? btn('Hesap saate gönderildi', 'done') + dateRow(`Son gönderim 14:32 · ${n} saat`)
        : btn('Hesabı saate gönder') + notice('Fenix 7\'ye gönderilemedi', 'Saat telefondan uzakta ya da saatte SNIPER TÜRK kapalı. Saati yaklaştırıp “Hesabı saate gönder”e dokunun.'));
    }
    html += sectionHeader('Saatte görünenler') + card(chips(st.off));
    html += sectionHeader('Saatten gelenler') + card(recvTiles(st.recv));
    return html;
  },
};
