// Seçenek A — Bölüm kartları (Hava Durumu düzeni).
const OPTION = {
  name: 'Seçenek A — Bölüm kartları',
  idea: 'Hava Durumu sayfasının düzeni: başlık + ⓘ, altında kart. Saatler, Saate gönderim, Saatte görünenler, Saatten gelenler sırayla. Saat markası ile “Saati bağla” Basınç Ölçer gibi aynı satırda.',
  infoExample: 'garmin',
  css: '',
  render(st, w) {
    const any = st.watches.length > 0;
    const conn = isConnected(st);
    const brand = st.brand || 'Garmin';
    const pick = `<div class="row2">${field('Saat markası', brand)}${btn(conn ? 'Başka saat bağla' : 'Saati bağla')}</div>`;
    let html = sectionHeader('Saatler', 'isteğe bağlı');
    if (!any) {
      // Boş sayfa tek bir iş gösterir: saati bağlamak.
      html += card(`<div class="cardtitle">Saatinizi bağlayın</div>
        <div class="lead">Saatinizin markasını seçip “Saati bağla”ya dokunun.</div>
        <div class="hint">${connectHint(brand)}</div>${pick}`);
      return html;
    }
    const rows = st.watches.map((x) => watchRow(x)).join('');
    if (!conn) return html + card(rows);
    html += card(`${rows}<div style="border-top:1px solid var(--line);margin-top:2px;padding-top:4px"><div class="hint">${connectHint(brand)}</div>${pick}</div>`);
    html += sectionHeader('Saate gönderim');
    html += card(st.send === 'ok'
      ? btn('Hesap saate gönderildi', 'done') + dateRow('Her yeni hesap kendiliğinden gider · son 14:32')
      : btn('Hesabı saate gönder') + notice('Fenix 7\'ye gönderilemedi', 'Saat telefondan uzakta ya da saatte SNIPER TÜRK kapalı. Saati yaklaştırıp “Hesabı saate gönder”e dokunun.'));
    html += sectionHeader('Saatte görünenler') + card(chips(st.off));
    html += sectionHeader('Saatten gelenler') + card(recvTiles(st.recv));
    return html;
  },
};
