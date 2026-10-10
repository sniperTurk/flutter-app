/// Explanations shown inside each Pro Ayarlar box when it is opened (owner,
/// 2026-10-09): plain enough for a child — what it is, why it matters, how
/// to get the value (and what happens when it is left empty).
class ProExplain {
  final String title, what, why, how;
  const ProExplain({
    required this.title,
    required this.what,
    required this.why,
    required this.how,
  });
}

abstract final class ProSectionInfo {
  static const incline = ProExplain(
    title: 'Tüfek eğimi',
    what:
        'Hedef seninle aynı seviyede değilse (tepede ya da vadide) tüfeğini '
        'yukarı veya aşağı eğersin. Bu eğikliğin açısı.',
    why:
        'Yerçekimi mermiyi hep dümdüz aşağı çeker. Eğik atışta mermi, '
        'mesafenin hepsi boyunca değil, sadece yatay kısmı boyunca düşer. Bu '
        'yüzden eğimi hesaba katmazsan hedefin üstüne vurursun; yokuş yukarı '
        'da yokuş aşağı da böyledir.',
    how:
        '"Telefonla ölç"e dokun. Telefonu dik tut, arka kamerası hedefe '
        'baksın. Ekrandaki artıyı hedefin üstüne getir ve "OK"a bas; açıyı '
        'telefon ölçer. Düz atışta 0 bırak.',
  );

  static const cant = ProExplain(
    title: 'Dürbün eğimi',
    what:
        'Tüfeği tutarken farkında olmadan sağa ya da sola yatırırsın. '
        'Dürbünün dik durmaması bu yatıklık.',
    why:
        'Dürbün yatınca "yukarı" çevirdiğin tıklar tam yukarı gitmez, biraz '
        'yana kayar. Mesafe uzadıkça bu kayma büyür.',
    how:
        'Tüfeği atış pozisyonundaki gibi tut. "Telefonla ölç"e dokun. '
        'Telefonu dik tut ve yan kenarını dürbünün üst kule kapağına ya da '
        'rayın düz yüzeyine dayayıp "Ölçülen açıyı al"a bas. Dürbünde su '
        'terazisi varsa ve dik tutuyorsan 0 bırak.',
  );

  static const windMax = ProExplain(
    title: 'Rüzgâr aralığı',
    what:
        'Rüzgâr hep aynı esmez; bazen sertleşir. Bu kutu, rüzgârın en sert '
        'anındaki hızını tahmin eder. Kendi ölçtüğün bir değer varsa onu '
        'yazabilirsin.',
    why:
        'Hedef ekranı yan düzeltmeyi tek sayı yerine bir aralık olarak '
        'gösterir, örneğin "3–5 tık sağa". Rüzgârın ne yapacağını bilemediğin '
        'anlarda nişanı nereye kaydıracağını görürsün.',
    how:
        'Senin bir şey girmene gerek yok; uygulama Hava Durumu\'ndaki rüzgârı '
        '1,5 ile çarpıp kendisi yazar. Rüzgâr ölçerin varsa ölçtüğün en '
        'yüksek değeri yazabilirsin. Kullanmak istemezsen kutuyu sil; aralık '
        'gösterilmez. "Otomatik doldur"a dokunursan yeniden otomatik olur.',
  );

  static const windZones = ProExplain(
    title: 'Rüzgâr bölgeleri',
    what:
        'Senin olduğun yerde rüzgâr başka, yolun ortasında başka, hedefin '
        'yanında başka esebilir. Bu iki kutu, ortadaki ve hedefteki rüzgâr.',
    why:
        'Mermi yolun her yerinde rüzgâr yer. Hedefte rüzgâr daha sertse sadece '
        'kendi yanındaki rüzgâra göre ayar yapınca ıskalarsın. Uzak mesafede '
        'bu fark büyür.',
    how:
        'Oradaki rüzgârı ölçemezsin, gözünle tahmin edersin:\n'
        '• Yapraklar hafifçe kıpırdıyor, yüzünde rüzgârı zor hissediyorsun: '
        '1–2 m/s\n'
        '• Yapraklar ve ince dallar sürekli sallanıyor, rüzgârı yüzünde rahat '
        'hissediyorsun: 3–4 m/s\n'
        '• Toz ve kâğıt uçuyor, küçük dallar sallanıyor: 5–7 m/s\n'
        '• Ağaçlar sallanıyor, rüzgâra karşı yürümek zorlaşıyor: 8 m/s ve '
        'üstü\n'
        'Çimen, ekin, bayrak ya da dürbünde titreşen sıcak havaya (serap) '
        'bakabilirsin. Boş bırakırsan her yerde Hava Durumu\'ndaki rüzgâr '
        'kullanılır.',
  );

  static const coriolis = ProExplain(
    title: 'Coriolis',
    what: 'Dünya dönerken mermi havadayken altından biraz kayar.',
    why:
        '500 m\'nin ötesinde birkaç santim fark eder. Kısa mesafede gerek yok.',
    how:
        'Bir şey ölçmene gerek yok. Telefon nerede olduğunu GPS\'ten, hangi '
        'yöne baktığını pusulasından alır. Telefonu hedefe çevirip iki düğmeye '
        'dokunman yeterli.',
  );

  static const gravity = ProExplain(
    title: 'Yerel yerçekimi: yerçekimi bile hesapta',
    what:
        'Yerçekimi dünyanın her yerinde aynı değildir. Dünya kutuplarda '
        'basık olduğu ve döndüğü için ekvatorda biraz zayıf, kutuplarda biraz '
        'güçlüdür; dağa çıktıkça da azalır.',
    why:
        'Mermiyi aşağı çeken kuvvet budur. Çoğu uygulama her yerde aynı sayıyı '
        'kullanır; Sniper Türk bulunduğun noktanın yerçekimiyle hesaplar. Son '
        'milimetreler bile hesapta.',
    how:
        'Bir şey girmene gerek yok. Enlem konumundan, irtifa Hava '
        'Durumu\'ndan alınır; yerçekimi kendiliğinden hesaplanır.',
  );

  static const movingTarget = ProExplain(
    title: 'Hareketli hedef',
    what:
        'Hedef yürüyor ya da koşuyorsa, mermi oraya varana kadar hedef biraz '
        'yer değiştirir.',
    why:
        'Hedefin tam üstüne nişan alırsan mermi geldiğinde hedef orada olmaz, '
        'arkasından geçer. Hedefin gittiği yöne biraz önden nişan alman '
        'gerekir. Hedef ekranı ne kadar önden alacağını söyler.',
    how:
        'Hedefin hızını tahmin et:\n'
        '• Yavaş yürüyen hayvan: 0,5–1 m/s\n'
        '• Normal yürüyüş: 1–1,5 m/s\n'
        '• Tırıs veya koşu: 3–5 m/s\n'
        'Sonra hangi yöne gittiğini seç. Hedef duruyorsa boş bırak.',
  );

  static const hitProbability = ProExplain(
    title: 'İsabet olasılığı',
    what: 'Bu atışta hedefi vurma şansın; örneğin "%72".',
    why:
        '"Buradan vurabilir miyim, yoksa yaklaşmalı mıyım?" sorusunun cevabı. '
        'Avda hayvanı yaralamamak için önemli.',
    how:
        'Aşağıya iki şey yaz:\n'
        '• Grup çapı: Sıfırladığın mesafede 5 atış at, birbirinden en uzak iki '
        'deliğin arasını ölç.\n'
        '• Hız farkı (SD): Kronograf cihazın atışların hızı ne kadar değişiyor '
        'diye gösterir. Cihazın yoksa boş bırak.\n'
        'Boş bırakırsan yüzde görünmez.',
  );

  static const turretScale = ProExplain(
    title: 'Kule ölçek katsayısı',
    what:
        'Dürbün kulesi üzerinde yazan kadar dönmeyebilir. Örneğin 10 tık '
        '"1 MRAD" demesine rağmen gerçekte biraz az ya da fazla kaydırabilir.',
    why:
        'Fark küçük görünür ama uzak mesafede çok tık çevirdiğinde birikir ve '
        'ıskalarsın.',
    how:
        'Kare testi yap: Hedefe bir atış yap, kuleyi 40 tık yukarı çevir, '
        'tekrar at. İki delik arasını ölç. Olması gereken mesafeye bölünce '
        'katsayı çıkar; örneğin 39 cm olması gerekirken 38 cm ise 0,97. Test '
        'yapmadıysan boş bırak.',
  );

  static const zeroOffset = ProExplain(
    title: 'Sıfır ofseti',
    what:
        'Tüfeği sıfırladığın mesafede grup tam ortaya değil, biraz yukarıya, '
        'aşağıya ya da yana düşüyor olabilir.',
    why:
        'Sıfırdaki küçük kayma her mesafeye taşınır. Uygulama bunu bilirse tüm '
        'hesaplarda düzeltir.',
    how:
        'Sıfır mesafesinde 5 atış at. Grubun ortası artıdan kaç cm yukarıda '
        'veya aşağıda, kaç cm sağda veya solda, onu yaz (aşağı ve sol için '
        'eksi). Tam ortadaysa boş bırak.',
  );

  static const spinDrift = ProExplain(
    title: 'Spin drift',
    what:
        'Namludaki yivler mermiyi döndürür. Dönen mermi uçarken yavaşça bir '
        'yana kayar; sağ yivde sağa. Yan rüzgâr da dönen mermiyi biraz yukarı '
        'ya da aşağı iter.',
    why:
        '300 m\'nin ötesinde birkaç santim fark eder. Kısa mesafede gerek yok.',
    how:
        'Düğmeyi aç ve mermi uzunluğunu yaz; kumpasla ölçebilir ya da '
        'kutusundan bakabilirsin. Yiv yönü ve yiv oranı profilden alınır.',
  );

  /// Shown under spin drift only on PCP profiles (owner, 2026-10-09).
  static const spinDriftPcpNote =
      'PCP\'de 200 m\'nin ötesinde, slug ile anlamlıdır; yakın mesafede '
      'açmana gerek yok.';

  static const powder = ProExplain(
    title: 'Barut sıcaklığı',
    what:
        'Barut sıcakta daha hızlı, soğukta daha yavaş yanar; mermi hızı havaya '
        'göre değişir.',
    why:
        'Yazın ölçtüğün hızla kışın atarsan mermi daha yavaş gider ve aşağı '
        'vurursun.',
    how:
        'Mühimmatın kutusunda ya da üreticinin sitesinde "sıcaklık '
        'hassasiyeti" yazar (örneğin %1 / 15 °C). Profildeki hızı hangi '
        'sıcaklıkta ölçtüysen onu da yaz. Bilmiyorsan boş bırak.',
  );
}
