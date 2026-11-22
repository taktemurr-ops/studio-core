import 'strings_phrases.dart';
import 'strings_world.dart';

/// Localization: Turkish, English, German, Spanish, French in [_base]
/// (order in every list: tr, en, de, es, fr), plus 28 world languages in
/// [kWorldStrings]. Missing texts fall back to English.
class Strings {
  static const _core = ['tr', 'en', 'de', 'es', 'fr'];

  /// All supported languages. Game text lists follow this order; a list
  /// shorter than the index falls back to English.
  static const languages = [..._core, ...kWorldLanguages];

  static const languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    ...kWorldLanguageNames,
  };

  /// Android reports some languages with legacy codes.
  static const _aliases = {'iw': 'he', 'in': 'id', 'tl': 'fil', 'no': 'nb', 'nn': 'nb'};

  final String lang;
  final Map<String, List<String>> extra;

  Strings(String lang, {this.extra = const {}})
      : lang = languages.contains(lang) ? lang : 'en';

  int get _i => languages.indexOf(lang);

  bool get rtl => kRtlLanguages.contains(lang);

  String t(String key, [Map<String, Object> params = const {}]) {
    final row = extra[key] ?? _base[key];
    String s;
    if (row != null && row.length > _i) {
      s = row[_i];
    } else {
      s = kWorldStrings[lang]?[key] ?? (row == null ? key : row[1]);
    }
    params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Picks a value for [lang] from a list in [languages] order.
  static String pick(List<String> l, String lang) {
    final i = languages.indexOf(lang);
    return i >= 0 && i < l.length ? l[i] : (l.length > 1 ? l[1] : l.first);
  }

  /// Oyun içi kısa metin: Türkçe ve İngilizce yazılır, diğer diller
  /// [kPhrases] tablosundan gelir. {0}, {1} yer tutucuları [args] ile dolar.
  static String tx(String lang, String tr, String en, [List<Object?> args = const []]) {
    var s = lang == 'tr' ? tr : en;
    if (lang != 'tr' && lang != 'en') {
      final code = _aliases[lang] ?? lang;
      final i = kPhraseLanguages.indexOf(code);
      final row = kPhrases[en];
      if (i >= 0 && row != null && i < row.length) s = row[i];
    }
    for (var k = 0; k < args.length; k++) {
      s = s.replaceAll('{$k}', '${args[k]}');
    }
    return s;
  }

  static String pickLanguage(String deviceLang) {
    final l = _aliases[deviceLang] ?? deviceLang;
    return languages.contains(l) ? l : 'en';
  }

  static const Map<String, List<String>> _base = {
    'play': ['Oyna', 'Play', 'Spielen', 'Jugar', 'Jouer'],
    'level': ['Bölüm {n}', 'Level {n}', 'Level {n}', 'Nivel {n}', 'Niveau {n}'],
    'world': ['Dünya {n}', 'World {n}', 'Welt {n}', 'Mundo {n}', 'Monde {n}'],
    'worlds': ['Dünyalar', 'Worlds', 'Welten', 'Mundos', 'Mondes'],
    'modes': ['Oyun modları', 'Game modes', 'Spielmodi', 'Modos de juego', 'Modes de jeu'],
    'mode_campaign': ['Macera', 'Adventure', 'Abenteuer', 'Aventura', 'Aventure'],
    'mode_endless': ['Sonsuz', 'Endless', 'Endlos', 'Infinito', 'Infini'],
    'mode_daily': ['Günün bölümü', 'Daily level', 'Tageslevel', 'Nivel diario', 'Niveau du jour'],
    'mode_weekly': ['Haftanın bölümü', 'Weekly level', 'Wochenlevel', 'Nivel semanal', 'Niveau de la semaine'],
    'mode_timeAttack': ['Zamana karşı', 'Time attack', 'Zeitrennen', 'Contrarreloj', 'Contre-la-montre'],
    'mode_zen': ['Zen', 'Zen', 'Zen', 'Zen', 'Zen'],
    'mode_challenge': ['Meydan okumalar', 'Challenges', 'Herausforderungen', 'Desafíos', 'Défis'],
    'mode_practice': ['Antrenman', 'Practice', 'Training', 'Práctica', 'Entraînement'],
    'mode_endless_d': ['Bitmeyen oyun, en yüksek skor', 'Play forever, beat your best', 'Endlos spielen, Rekord knacken', 'Juega sin fin, supera tu récord', 'Jouez sans fin, battez votre record'],
    'mode_timeAttack_d': ['Süre bitmeden en yüksek skor', 'Score big before time runs out', 'Punkte sammeln, bevor die Zeit abläuft', 'Puntúa antes de que acabe el tiempo', 'Marquez avant la fin du temps'],
    'mode_zen_d': ['Stressiz, kaybetmek yok', 'No stress, no game over', 'Kein Stress, kein Game Over', 'Sin estrés, sin derrota', 'Sans stress, sans défaite'],
    'mode_challenge_d': ['150 özel görev bölümü', '150 special challenge levels', '150 Spezial-Level', '150 niveles especiales', '150 niveaux spéciaux'],
    'mode_daily_d': ['Herkes için aynı bulmaca', 'Same puzzle for everyone', 'Gleiches Rätsel für alle', 'El mismo para todos', 'Le même pour tous'],
    'mode_weekly_d': ['Zorlu haftalık bölüm', 'A tough weekly level', 'Ein hartes Wochenlevel', 'Un nivel semanal difícil', 'Un niveau hebdo difficile'],
    'home': ['Ana sayfa', 'Home', 'Start', 'Inicio', 'Accueil'],
    'daily': ['Günlük', 'Daily', 'Täglich', 'Diario', 'Quotidien'],
    'collection': ['Koleksiyon', 'Collection', 'Sammlung', 'Colección', 'Collection'],
    'achievements': ['Başarımlar', 'Achievements', 'Erfolge', 'Logros', 'Succès'],
    'profile': ['Profil', 'Profile', 'Profil', 'Perfil', 'Profil'],
    'shop': ['Mağaza', 'Shop', 'Shop', 'Tienda', 'Boutique'],
    'settings': ['Ayarlar', 'Settings', 'Einstellungen', 'Ajustes', 'Paramètres'],
    'coins': ['Altın', 'Coins', 'Münzen', 'Monedas', 'Pièces'],
    'gems': ['Elmas', 'Gems', 'Edelsteine', 'Gemas', 'Gemmes'],
    'hints': ['İpucu', 'Hints', 'Tipps', 'Pistas', 'Indices'],
    'boosters': ['Güçlendirici', 'Boosters', 'Booster', 'Potenciadores', 'Bonus'],
    'hint': ['İpucu', 'Hint', 'Tipp', 'Pista', 'Indice'],
    'undo': ['Geri al', 'Undo', 'Rückgängig', 'Deshacer', 'Annuler'],
    'restart': ['Yeniden başla', 'Restart', 'Neustart', 'Reiniciar', 'Recommencer'],
    'pause': ['Duraklat', 'Pause', 'Pause', 'Pausa', 'Pause'],
    'resume': ['Devam et', 'Resume', 'Weiter', 'Continuar', 'Reprendre'],
    'quit': ['Çık', 'Quit', 'Beenden', 'Salir', 'Quitter'],
    'next': ['Sonraki', 'Next', 'Weiter', 'Siguiente', 'Suivant'],
    'retry': ['Tekrar dene', 'Try again', 'Nochmal', 'Reintentar', 'Réessayer'],
    'win_title': ['Harika!', 'Great job!', 'Super!', '¡Genial!', 'Bravo !'],
    'lose_title': ['Olmadı', 'Not this time', 'Diesmal nicht', 'Esta vez no', 'Pas cette fois'],
    'score': ['Skor', 'Score', 'Punkte', 'Puntos', 'Score'],
    'best': ['En iyi', 'Best', 'Bestwert', 'Mejor', 'Meilleur'],
    'new_record': ['Yeni rekor!', 'New record!', 'Neuer Rekord!', '¡Nuevo récord!', 'Nouveau record !'],
    'time': ['Süre', 'Time', 'Zeit', 'Tiempo', 'Temps'],
    'moves': ['Hamle', 'Moves', 'Züge', 'Movimientos', 'Coups'],
    'moves_left': ['Kalan hamle', 'Moves left', 'Züge übrig', 'Movimientos restantes', 'Coups restants'],
    'goal': ['Hedef', 'Goal', 'Ziel', 'Objetivo', 'Objectif'],
    'reward': ['Ödül', 'Reward', 'Belohnung', 'Recompensa', 'Récompense'],
    'claim': ['Al', 'Claim', 'Abholen', 'Reclamar', 'Récupérer'],
    'claimed': ['Alındı', 'Claimed', 'Abgeholt', 'Reclamado', 'Récupéré'],
    'locked': ['Kilitli', 'Locked', 'Gesperrt', 'Bloqueado', 'Verrouillé'],
    'equip': ['Kullan', 'Use', 'Nutzen', 'Usar', 'Utiliser'],
    'equipped': ['Kullanılıyor', 'In use', 'Aktiv', 'En uso', 'Actif'],
    'buy': ['Satın al', 'Buy', 'Kaufen', 'Comprar', 'Acheter'],
    'double_reward': ['Reklam izle, ödülü 2 katına çıkar', 'Watch an ad to double', 'Werbung ansehen: doppelt', 'Ver anuncio y duplicar', 'Regarder une pub : doubler'],
    'free_hint_ad': ['Reklam izle, ipucu kazan', 'Watch an ad for a hint', 'Werbung für einen Tipp', 'Anuncio por una pista', 'Pub pour un indice'],
    'no_hints': ['İpucun kalmadı', 'No hints left', 'Keine Tipps mehr', 'No quedan pistas', "Plus d'indices"],
    'daily_login': ['Günlük giriş ödülü', 'Daily login reward', 'Tägliche Belohnung', 'Premio diario', 'Récompense quotidienne'],
    'day_n': ['{n}. gün', 'Day {n}', 'Tag {n}', 'Día {n}', 'Jour {n}'],
    'streak': ['Seri: {n} gün', 'Streak: {n} days', 'Serie: {n} Tage', 'Racha: {n} días', 'Série : {n} jours'],
    'wheel': ['Günlük hediye', 'Daily gift', 'Tagesgeschenk', 'Regalo diario', 'Cadeau du jour'],
    'spin': ['Aç', 'Open', 'Öffnen', 'Abrir', 'Ouvrir'],
    'come_back_tomorrow': ['Yarın tekrar gel', 'Come back tomorrow', 'Komm morgen wieder', 'Vuelve mañana', 'Revenez demain'],
    'surprise': ['Günlük sürpriz', 'Daily surprise', 'Tagesüberraschung', 'Sorpresa diaria', 'Surprise du jour'],
    'surprise_hint': ['Bugün 3 bölüm kazan, sürprizi aç', 'Win 3 levels today to open', 'Gewinne heute 3 Level', 'Gana 3 niveles hoy', 'Gagnez 3 niveaux aujourd\'hui'],
    'daily_missions': ['Günlük görevler', 'Daily missions', 'Tagesaufgaben', 'Misiones diarias', 'Missions du jour'],
    'weekly_missions': ['Haftalık görevler', 'Weekly missions', 'Wochenaufgaben', 'Misiones semanales', 'Missions de la semaine'],
    'weekly_goal': ['Haftalık hedefin: {a}/{b} galibiyet', 'Weekly goal: {a}/{b} wins', 'Wochenziel: {a}/{b} Siege', 'Meta semanal: {a}/{b}', 'Objectif hebdo : {a}/{b}'],
    'daily_record': ['Bugünün rekoru: {n}', "Today's record: {n}", 'Tagesrekord: {n}', 'Récord de hoy: {n}', 'Record du jour : {n}'],
    'welcome_back': ['Tekrar hoş geldin!', 'Welcome back!', 'Willkommen zurück!', '¡Bienvenido de nuevo!', 'Bon retour !'],
    'welcome_back_d': ['Seni özledik, bu hediye senin.', 'We missed you, here is a gift.', 'Wir haben dich vermisst.', 'Te echamos de menos.', 'Vous nous avez manqué.'],
    'mission_win': ['{n} bölüm kazan', 'Win {n} levels', 'Gewinne {n} Level', 'Gana {n} niveles', 'Gagnez {n} niveaux'],
    'mission_play': ['{n} bölüm oyna', 'Play {n} levels', 'Spiele {n} Level', 'Juega {n} niveles', 'Jouez {n} niveaux'],
    'mission_stars': ['{n} yıldız topla', 'Collect {n} stars', 'Sammle {n} Sterne', 'Consigue {n} estrellas', 'Gagnez {n} étoiles'],
    'mission_three': ['{n} bölümü 3 yıldızla bitir', 'Get 3 stars {n} times', '{n}× 3 Sterne', '3 estrellas {n} veces', '3 étoiles {n} fois'],
    'mission_nohint': ['İpucusuz {n} galibiyet', '{n} wins without hints', '{n} Siege ohne Tipp', '{n} victorias sin pistas', '{n} victoires sans indice'],
    'mission_coins': ['{n} altın kazan', 'Earn {n} coins', 'Verdiene {n} Münzen', 'Gana {n} monedas', 'Gagnez {n} pièces'],
    'mission_daily': ['Günün bölümünü tamamla', 'Finish the daily level', 'Schaffe das Tageslevel', 'Completa el nivel diario', 'Finissez le niveau du jour'],
    'mission_endless': ['{n} sonsuz mod oyna', 'Play {n} endless runs', '{n} Endlos-Runden', '{n} partidas infinitas', '{n} parties infinies'],
    'mission_time': ['{n} zamana karşı oyna', 'Play {n} time attacks', '{n} Zeitrennen', '{n} contrarreloj', '{n} contre-la-montre'],
    'mission_challenge': ['{n} meydan okuma kazan', 'Win {n} challenges', '{n} Herausforderungen', 'Gana {n} desafíos', 'Gagnez {n} défis'],
    'mission_fast': ['{n} bölümü 30 sn altında bitir', 'Win {n} levels under 30s', '{n} Level unter 30 s', '{n} niveles en <30 s', '{n} niveaux en <30 s'],
    'mission_stat': ['{stat}: {n}', '{stat}: {n}', '{stat}: {n}', '{stat}: {n}', '{stat}: {n}'],
    'ach_levels': ['{n} bölüm tamamla', 'Complete {n} levels', 'Schaffe {n} Level', 'Completa {n} niveles', 'Terminez {n} niveaux'],
    'ach_stat': ['{stat}: {n}', '{stat}: {n}', '{stat}: {n}', '{stat}: {n}', '{stat}: {n}'],
    'ach_streak': ['{n} günlük giriş serisi', '{n}-day login streak', '{n}-Tage-Serie', 'Racha de {n} días', 'Série de {n} jours'],
    'ach_winstreak': ['Üst üste {n} galibiyet', '{n} wins in a row', '{n} Siege in Folge', '{n} victorias seguidas', '{n} victoires de suite'],
    'ach_plevel': ['Oyuncu seviyesi {n}', 'Reach player level {n}', 'Spielerlevel {n}', 'Nivel de jugador {n}', 'Niveau joueur {n}'],
    'ach_collection': ['{n} koleksiyon parçası', 'Own {n} collectibles', '{n} Sammelobjekte', '{n} coleccionables', '{n} objets'],
    'ach_worlds': ['{n} dünya bitir', 'Finish {n} worlds', 'Schaffe {n} Welten', 'Termina {n} mundos', 'Finissez {n} mondes'],
    'hidden_ach': ['Gizli başarım', 'Hidden achievement', 'Geheimer Erfolg', 'Logro oculto', 'Succès caché'],
    'unlocked_n': ['{a}/{b} açıldı', '{a}/{b} unlocked', '{a}/{b} freigeschaltet', '{a}/{b} desbloqueados', '{a}/{b} débloqués'],
    'achievement_unlocked': ['Başarım açıldı!', 'Achievement unlocked!', 'Erfolg freigeschaltet!', '¡Logro desbloqueado!', 'Succès débloqué !'],
    'item_unlocked': ['Yeni koleksiyon parçası!', 'New collectible!', 'Neues Sammelobjekt!', '¡Nuevo coleccionable!', 'Nouvel objet !'],
    'level_up': ['Seviye atladın: {n}', 'Level up: {n}', 'Level-Up: {n}', 'Subes de nivel: {n}', 'Niveau supérieur : {n}'],
    'tier_beginner': ['Başlangıç', 'Beginner', 'Anfänger', 'Principiante', 'Débutant'],
    'tier_developing': ['Gelişim', 'Rising', 'Aufsteiger', 'En progreso', 'En progrès'],
    'tier_expert': ['Uzman', 'Expert', 'Experte', 'Experto', 'Expert'],
    'tier_master': ['Usta', 'Master', 'Meister', 'Maestro', 'Maître'],
    'tier_legend': ['Efsane', 'Legend', 'Legende', 'Leyenda', 'Légende'],
    'type_theme': ['Temalar', 'Themes', 'Themen', 'Temas', 'Thèmes'],
    'type_skin': ['Görünümler', 'Skins', 'Skins', 'Aspectos', 'Apparences'],
    'type_badge': ['Rozetler', 'Badges', 'Abzeichen', 'Insignias', 'Badges'],
    'type_avatar': ['Avatarlar', 'Avatars', 'Avatare', 'Avatares', 'Avatars'],
    'type_frame': ['Çerçeveler', 'Frames', 'Rahmen', 'Marcos', 'Cadres'],
    'type_effect': ['Efektler', 'Effects', 'Effekte', 'Efectos', 'Effets'],
    'unlock_world': ['{n}. dünyada açılır', 'Unlocks in world {n}', 'Ab Welt {n}', 'Se abre en el mundo {n}', 'Monde {n}'],
    'unlock_plevel': ['Seviye {n}', 'Player level {n}', 'Spielerlevel {n}', 'Nivel {n}', 'Niveau {n}'],
    'unlock_stars': ['{n} yıldız', '{n} stars', '{n} Sterne', '{n} estrellas', '{n} étoiles'],
    'unlock_ach': ['{n} başarım', '{n} achievements', '{n} Erfolge', '{n} logros', '{n} succès'],
    'unlock_premium': ['Premium', 'Premium', 'Premium', 'Premium', 'Premium'],
    'unlock_wheel': ['Günlük hediyeden', 'From the daily gift', 'Aus dem Tagesgeschenk', 'Del regalo diario', 'Du cadeau du jour'],
    'stats': ['İstatistikler', 'Statistics', 'Statistiken', 'Estadísticas', 'Statistiques'],
    'records': ['Rekorlar', 'Records', 'Rekorde', 'Récords', 'Records'],
    'player_level': ['Oyuncu seviyesi', 'Player level', 'Spielerlevel', 'Nivel de jugador', 'Niveau joueur'],
    'backup': ['Yedekle', 'Back up', 'Sichern', 'Copia', 'Sauvegarder'],
    'restore_backup': ['Yedekten yükle', 'Restore backup', 'Wiederherstellen', 'Restaurar', 'Restaurer'],
    'backup_copied': ['Yedek kodu panoya kopyalandı', 'Backup code copied', 'Sicherungscode kopiert', 'Código copiado', 'Code copié'],
    'backup_invalid': ['Yedek kodu geçersiz', 'Invalid backup code', 'Ungültiger Code', 'Código no válido', 'Code invalide'],
    'backup_restored': ['Yedek yüklendi', 'Backup restored', 'Wiederhergestellt', 'Restaurado', 'Restauré'],
    'paste_backup': ['Yedek kodunu yapıştır', 'Paste your backup code', 'Code einfügen', 'Pega tu código', 'Collez votre code'],
    'cancel': ['İptal', 'Cancel', 'Abbrechen', 'Cancelar', 'Annuler'],
    'ok': ['Tamam', 'OK', 'OK', 'OK', 'OK'],
    'language': ['Dil', 'Language', 'Sprache', 'Idioma', 'Langue'],
    'sound': ['Ses efektleri', 'Sound effects', 'Soundeffekte', 'Efectos de sonido', 'Effets sonores'],
    'music': ['Müzik', 'Music', 'Musik', 'Música', 'Musique'],
    'haptics': ['Titreşim', 'Haptics', 'Vibration', 'Vibración', 'Vibrations'],
    'reduced_motion': ['Animasyonları azalt', 'Reduce motion', 'Bewegung reduzieren', 'Reducir animación', 'Réduire les animations'],
    'color_blind': ['Renk körü modu (semboller)', 'Color-blind mode (symbols)', 'Farbenblind-Modus', 'Modo daltónico', 'Mode daltonien'],
    'left_handed': ['Solak düzen', 'Left-handed layout', 'Linkshänder', 'Modo zurdo', 'Mode gaucher'],
    'text_size': ['Yazı boyutu', 'Text size', 'Textgröße', 'Tamaño de texto', 'Taille du texte'],
    'privacy': ['Gizlilik', 'Privacy', 'Datenschutz', 'Privacidad', 'Confidentialité'],
    'privacy_policy': ['Gizlilik politikası', 'Privacy policy', 'Datenschutzerklärung', 'Política de privacidad', 'Politique de confidentialité'],
    'ad_settings': ['Reklam tercihleri', 'Ad preferences', 'Werbeeinstellungen', 'Preferencias de anuncios', 'Préférences pub'],
    'analytics_opt': ['Anonim kullanım verisi paylaş', 'Share anonymous usage data', 'Anonyme Nutzungsdaten', 'Compartir datos anónimos', 'Partager des données anonymes'],
    'delete_data': ['Tüm verilerimi sil', 'Delete all my data', 'Alle Daten löschen', 'Borrar mis datos', 'Supprimer mes données'],
    'delete_confirm': ['Tüm ilerlemen kalıcı olarak silinecek. Emin misin?', 'All progress will be permanently deleted. Are you sure?', 'Aller Fortschritt wird gelöscht. Sicher?', 'Se borrará todo. ¿Seguro?', 'Tout sera supprimé. Sûr ?'],
    'delete': ['Sil', 'Delete', 'Löschen', 'Borrar', 'Supprimer'],
    'how_to_play': ['Nasıl oynanır?', 'How to play', 'Spielanleitung', 'Cómo jugar', 'Comment jouer'],
    'about': ['Hakkında', 'About', 'Über', 'Acerca de', 'À propos'],
    'version': ['Sürüm', 'Version', 'Version', 'Versión', 'Version'],
    'restore_purchases': ['Satın alımları geri yükle', 'Restore purchases', 'Käufe wiederherstellen', 'Restaurar compras', 'Restaurer les achats'],
    'remove_ads': ['Reklamları kaldır', 'Remove ads', 'Werbung entfernen', 'Quitar anuncios', 'Supprimer les pubs'],
    'premium_pack': ['Premium paket', 'Premium pack', 'Premium-Paket', 'Paquete premium', 'Pack premium'],
    'hub_welcome': ['Hoş geldin!', 'Welcome!', 'Willkommen!', '¡Bienvenido!', 'Bienvenue !'],
    'hub_welcome_body': ['{n} oyun tek uygulamada. Nereden başlayacağını bilmiyorsan şunlardan birini dene:', '{n} games in one app. Not sure where to start? Try one of these:', '{n} Spiele in einer App. Wo anfangen? Probier eins davon:', '{n} juegos en una app. ¿No sabes por dónde empezar? Prueba uno de estos:', '{n} jeux dans une seule appli. Par où commencer ? Essaie l’un de ceux-ci :'],
    'hub_tips': ['• Bütün oyunlar internetsiz oynanır.
• Her oyunun ilerlemesi ayrı saklanır.
• Reklamsız ve Premium bir kez alınır, buradaki bütün oyunlarda geçerli olur.', '• Every game plays offline.
• Each game keeps its own progress.
• No Ads and Premium are bought once and work in every game here.', '• Alle Spiele funktionieren offline.
• Jedes Spiel speichert seinen eigenen Fortschritt.
• Werbefrei und Premium kaufst du einmal – für alle Spiele hier.', '• Todos los juegos funcionan sin conexión.
• Cada juego guarda su propio progreso.
• Sin anuncios y Premium se compran una vez y valen para todos los juegos de aquí.', '• Tous les jeux fonctionnent hors ligne.
• Chaque jeu garde sa propre progression.
• Sans pub et Premium s’achètent une fois et valent pour tous les jeux ici.'],
    'hub_browse': ['Hepsine göz at', 'Browse all', 'Alle ansehen', 'Ver todos', 'Tout parcourir'],
    'rejoin_title': ['Yarım kalan maç', 'Unfinished match', 'Unbeendetes Spiel', 'Partida sin terminar', 'Partie inachevée'],
    'rejoin_body': ['Masa hâlâ sürüyor. Sen yokken yerine bot oynadı; kaldığın yerden devam etmek ister misin?', 'The table is still playing. A bot covered for you while you were away. Jump back in?', 'Der Tisch spielt noch. Ein Bot hat für dich übernommen. Weiterspielen?', 'La mesa sigue jugando. Un bot jugó por ti mientras no estabas. ¿Vuelves?', 'La table joue encore. Un robot a pris ta place pendant ton absence. Revenir ?'],
    'rejoin_yes': ['Maça dön', 'Rejoin', 'Zurück zum Tisch', 'Volver', 'Revenir'],
    'later': ['Sonra', 'Later', 'Später', 'Luego', 'Plus tard'],
    'invite_title': ['Masa daveti', 'Table invite', 'Einladung an den Tisch', 'Invitación a la mesa', 'Invitation à la table'],
    'invite_body': ['{name} seni {game} masasına çağırıyor.', '{name} invited you to a {game} table.', '{name} lädt dich zu {game} ein.', '{name} te invita a una mesa de {game}.', '{name} t’invite à une table de {game}.'],
    'invite_join': ['Katıl', 'Join', 'Beitreten', 'Unirse', 'Rejoindre'],
    'call_friend': ['Arkadaşını çağır', 'Call a friend', 'Freund einladen', 'Llamar a un amigo', 'Appeler un ami'],
    'invite_sent': ['Davet gönderildi', 'Invite sent', 'Einladung gesendet', 'Invitación enviada', 'Invitation envoyée'],
    'invite': ['Davet et', 'Invite', 'Einladen', 'Invitar', 'Inviter'],
    'terms_title': ['Çevrimiçi oyun kuralları', 'Online play rules', 'Regeln für Online-Spiele', 'Normas del juego en línea', 'Règles du jeu en ligne'],
    'terms_body': ['• Saygılı ol: küfür, hakaret, nefret söylemi ve taciz yasak.
• Kişisel bilgi (telefon, adres, sosyal medya) paylaşma, isteme.
• Hile, dolandırıcılık ve reklam yasak.
• Kurallara uymayan hesaplar uyarılmadan kapatılabilir; şikâyetler incelenir.
• Çevrimiçi oyun 13 yaş ve üzeri içindir; yazılı sohbet 16 yaş ve üzeri.', '• Be respectful: swearing, insults, hate speech and harassment are not allowed.
• Do not share or ask for personal details (phone, address, social media).
• No cheating, scams or advertising.
• Accounts that break the rules may be closed without warning; reports are reviewed.
• Online play is for ages 13+; typed chat is for ages 16+.', '• Sei respektvoll: Beleidigungen, Hassrede und Belästigung sind verboten.
• Teile oder erfrage keine persönlichen Daten (Telefon, Adresse, soziale Medien).
• Kein Schummeln, Betrug oder Werbung.
• Konten, die gegen die Regeln verstoßen, können ohne Warnung gesperrt werden; Meldungen werden geprüft.
• Online-Spiel ab 13 Jahren; Text-Chat ab 16 Jahren.', '• Sé respetuoso: prohibidos los insultos, el odio y el acoso.
• No compartas ni pidas datos personales (teléfono, dirección, redes).
• Prohibidas las trampas, estafas y publicidad.
• Las cuentas que incumplan las normas pueden cerrarse sin aviso; se revisan las denuncias.
• El juego en línea es para mayores de 13; el chat escrito, para mayores de 16.', '• Soyez respectueux : insultes, haine et harcèlement sont interdits.
• Ne partagez ni ne demandez d’informations personnelles (téléphone, adresse, réseaux).
• Pas de triche, d’arnaque ni de publicité.
• Les comptes qui enfreignent les règles peuvent être fermés sans préavis ; les signalements sont examinés.
• Le jeu en ligne est réservé aux 13 ans et plus ; la discussion écrite aux 16 ans et plus.'],
    'terms_accept': ['Kabul ediyorum', 'I agree', 'Ich stimme zu', 'Acepto', 'J’accepte'],
    'transfer_title': ['Telefon değiştirme', 'Changing phones', 'Handywechsel', 'Cambio de teléfono', 'Changement de téléphone'],
    'transfer_create': ['Taşıma kodu al', 'Get a transfer code', 'Übertragungscode holen', 'Obtener código de traspaso', 'Obtenir un code de transfert'],
    'transfer_code_info': ['Bu kodu yeni telefonunda Profil bölümüne gir: ilerlemen, adın, ligin ve hediyelerin taşınır. Kodu kimseyle paylaşma, bir kez kullanılır.', 'Enter this code under Profile on your new phone: your progress, name, league and gifts move over. Do not share it; it works once.', 'Gib diesen Code auf dem neuen Handy unter Profil ein: Fortschritt, Name, Liga und Geschenke ziehen um. Nicht teilen; nur einmal gültig.', 'Introduce este código en Perfil en tu nuevo teléfono: se trasladan progreso, nombre, liga y regalos. No lo compartas; sirve una vez.', 'Saisissez ce code dans Profil sur le nouveau téléphone : progression, nom, ligue et cadeaux sont transférés. Ne le partagez pas ; usage unique.'],
    'transfer_enter': ['Taşıma kodunu gir', 'Enter transfer code', 'Übertragungscode eingeben', 'Introduce el código', 'Saisir le code'],
    'transfer_done': ['İlerlemen taşındı', 'Your progress has moved over', 'Dein Fortschritt wurde übertragen', 'Tu progreso se ha trasladado', 'Votre progression a été transférée'],
    'delete_account': ['Çevrimiçi hesabımı sil', 'Delete my online account', 'Mein Online-Konto löschen', 'Eliminar mi cuenta en línea', 'Supprimer mon compte en ligne'],
    'delete_account_q': ['Profilin, arkadaşların, hediyelerin, sıralamadaki yerin ve bulut yedeğin kalıcı olarak silinir. Cihazdaki ilerlemen kalır.', 'Your profile, friends, gifts, leaderboard entries and cloud backup will be deleted for good. Progress on this device stays.', 'Profil, Freunde, Geschenke, Ranglisteneinträge und Cloud-Sicherung werden endgültig gelöscht. Der Fortschritt auf dem Gerät bleibt.', 'Se eliminarán para siempre tu perfil, amigos, regalos, clasificaciones y copia en la nube. Tu progreso en el dispositivo se conserva.', 'Votre profil, vos amis, cadeaux, classements et sauvegarde cloud seront supprimés définitivement. La progression sur l’appareil reste.'],
    'reminder_setting': ['Günlük hatırlatma', 'Daily reminder', 'Tägliche Erinnerung', 'Recordatorio diario', 'Rappel quotidien'],
    'reminder_title': ['Günlük ödülün hazır 🎁', 'Your daily reward is ready 🎁', 'Deine Tagesbelohnung wartet 🎁', 'Tu recompensa diaria está lista 🎁', 'Votre récompense du jour est prête 🎁'],
    'reminder_body': ['Günün bulmacası ve görevleri seni bekliyor.', 'Today’s puzzle and missions are waiting.', 'Das Tagesrätsel und die Missionen warten.', 'El reto y las misiones de hoy te esperan.', 'Le défi et les missions du jour vous attendent.'],
    'mode_online': ['Çevrimiçi oyna', 'Play online', 'Online spielen', 'Jugar en línea', 'Jouer en ligne'],
    'mode_online_d': ['Rakip bul ya da arkadaşını davet et', 'Find a rival or invite a friend', 'Finde Gegner oder lade Freunde ein', 'Busca rival o invita a un amigo', 'Trouvez un adversaire ou invitez un ami'],
    'leaderboards': ['Sıralama', 'Leaderboards', 'Bestenlisten', 'Clasificación', 'Classements'],
    'board_daily': ['Bugün', 'Today', 'Heute', 'Hoy', 'Aujourd’hui'],
    'board_weekly': ['Bu hafta', 'This week', 'Diese Woche', 'Esta semana', 'Cette semaine'],
    'board_league': ['Lig', 'League', 'Liga', 'Liga', 'Ligue'],
    'league_bronze': ['Bronz', 'Bronze', 'Bronze', 'Bronce', 'Bronze'],
    'league_silver': ['Gümüş', 'Silver', 'Silber', 'Plata', 'Argent'],
    'league_gold': ['Altın', 'Gold', 'Gold', 'Oro', 'Or'],
    'league_platinum': ['Platin', 'Platinum', 'Platin', 'Platino', 'Platine'],
    'league_diamond': ['Elmas', 'Diamond', 'Diamant', 'Diamante', 'Diamant'],
    'gifts_received': ['Aldığın hediyeler', 'Gifts received', 'Erhaltene Geschenke', 'Regalos recibidos', 'Cadeaux reçus'],
    'cloud_backup': ['Buluta yedekle', 'Back up to cloud', 'In der Cloud sichern', 'Copia en la nube', 'Sauvegarder dans le cloud'],
    'cloud_restore': ['Buluttan geri yükle', 'Restore from cloud', 'Aus der Cloud wiederherstellen', 'Restaurar desde la nube', 'Restaurer depuis le cloud'],
    'cloud_done': ['Tamamlandı', 'Done', 'Erledigt', 'Listo', 'Terminé'],
    'rating': ['Lig puanı', 'League points', 'Ligapunkte', 'Puntos de liga', 'Points de ligue'],
    'chat_hi': ['Merhaba!', 'Hello!', 'Hallo!', '¡Hola!', 'Salut !'],
    'chat_gg': ['İyi oyun!', 'Good game!', 'Gutes Spiel!', '¡Buena partida!', 'Bien joué la partie !'],
    'chat_wp': ['Çok iyiydi!', 'Well played!', 'Gut gespielt!', '¡Bien jugado!', 'Bien joué !'],
    'chat_thanks': ['Teşekkürler!', 'Thanks!', 'Danke!', '¡Gracias!', 'Merci !'],
    'chat_oops': ['Hay aksi!', 'Oops!', 'Hoppla!', '¡Uy!', 'Oups !'],
    'chat_hurry': ['Hadi biraz hızlı!', 'Let’s speed up!', 'Etwas schneller!', '¡Vamos, más rápido!', 'On accélère !'],
    'chat_wow': ['Vay be!', 'Wow!', 'Wow!', '¡Guau!', 'Waouh !'],
    'chat_bye': ['Görüşürüz!', 'See you!', 'Bis bald!', '¡Hasta luego!', 'À plus !'],
    'gift_coffee': ['Kahve', 'Coffee', 'Kaffee', 'Café', 'Café'],
    'gift_tea': ['Çay', 'Tea', 'Tee', 'Té', 'Thé'],
    'gift_applause': ['Alkış', 'Applause', 'Applaus', 'Aplausos', 'Applaudissements'],
    'gift_rose': ['Gül', 'Rose', 'Rose', 'Rosa', 'Rose'],
    'gift_cake': ['Pasta', 'Cake', 'Kuchen', 'Pastel', 'Gâteau'],
    'gift_trophy': ['Kupa', 'Trophy', 'Pokal', 'Trofeo', 'Trophée'],
    'gift_crown': ['Taç', 'Crown', 'Krone', 'Corona', 'Couronne'],
    'chat': ['Sohbet', 'Chat', 'Chat', 'Chat', 'Discussion'],
    'gifts': ['Hediyeler', 'Gifts', 'Geschenke', 'Regalos', 'Cadeaux'],
    'players': ['Oyuncular', 'Players', 'Spieler', 'Jugadores', 'Joueurs'],
    'send': ['Gönder', 'Send', 'Senden', 'Enviar', 'Envoyer'],
    'type_message': ['Mesaj yaz…', 'Type a message…', 'Nachricht schreiben…', 'Escribe un mensaje…', 'Écrire un message…'],
    'free_left': ['Bugün {n} ücretsiz', '{n} free today', 'Heute {n} gratis', '{n} gratis hoy', '{n} gratuits aujourd’hui'],
    'not_enough_gems': ['Yeterli elmas yok', 'Not enough gems', 'Nicht genug Edelsteine', 'No tienes gemas suficientes', 'Pas assez de gemmes'],
    'report': ['Şikâyet et', 'Report', 'Melden', 'Denunciar', 'Signaler'],
    'block': ['Engelle', 'Block', 'Blockieren', 'Bloquear', 'Bloquer'],
    'mute': ['Sustur', 'Mute', 'Stummschalten', 'Silenciar', 'Masquer'],
    'reported': ['Teşekkürler, inceleyeceğiz.', 'Thanks, we will review it.', 'Danke, wir prüfen das.', 'Gracias, lo revisaremos.', 'Merci, nous allons vérifier.'],
    'blocked_msg': ['Engellendi', 'Blocked', 'Blockiert', 'Bloqueado', 'Bloqué'],
    'nickname': ['Takma ad', 'Nickname', 'Spitzname', 'Apodo', 'Pseudo'],
    'avatar': ['Avatar', 'Avatar', 'Avatar', 'Avatar', 'Avatar'],
    'age16': ['16 yaşından büyüğüm (yazılı sohbet açılır)', 'I am 16 or older (enables text chat)', 'Ich bin 16 oder älter (Text-Chat an)', 'Tengo 16 años o más (activa el chat)', 'J’ai 16 ans ou plus (active la discussion)'],
    'friend_code': ['Arkadaş kodun', 'Your friend code', 'Dein Freundescode', 'Tu código de amigo', 'Votre code ami'],
    'add_friend': ['Arkadaş ekle', 'Add friend', 'Freund hinzufügen', 'Añadir amigo', 'Ajouter un ami'],
    'friends': ['Arkadaşlar', 'Friends', 'Freunde', 'Amigos', 'Amis'],
    'no_friends': ['Henüz arkadaş yok', 'No friends yet', 'Noch keine Freunde', 'Aún no tienes amigos', 'Pas encore d’amis'],
    'friend_added': ['Arkadaş eklendi', 'Friend added', 'Freund hinzugefügt', 'Amigo añadido', 'Ami ajouté'],
    'code_not_found': ['Kod bulunamadı', 'Code not found', 'Code nicht gefunden', 'Código no encontrado', 'Code introuvable'],
    'online_play': ['Çevrimiçi oyna', 'Play online', 'Online spielen', 'Jugar en línea', 'Jouer en ligne'],
    'online_play_d': ['Rakip bul ya da arkadaşını davet et', 'Find a rival or invite a friend', 'Finde Gegner oder lade Freunde ein', 'Busca rival o invita a un amigo', 'Trouvez un adversaire ou invitez un ami'],
    'quick_match': ['Hızlı eşleşme', 'Quick match', 'Schnelles Spiel', 'Partida rápida', 'Partie rapide'],
    'invite_friend': ['Arkadaşını davet et', 'Invite a friend', 'Freund einladen', 'Invitar a un amigo', 'Inviter un ami'],
    'join_code': ['Kodla katıl', 'Join with code', 'Mit Code beitreten', 'Unirse con código', 'Rejoindre avec un code'],
    'enter_code': ['Davet kodu', 'Invite code', 'Einladungscode', 'Código de invitación', 'Code d’invitation'],
    'waiting_players': ['Oyuncular bekleniyor…', 'Waiting for players…', 'Warte auf Spieler…', 'Esperando jugadores…', 'En attente de joueurs…'],
    'share_code': ['Bu kodu arkadaşına gönder', 'Send this code to your friend', 'Schick diesen Code deinem Freund', 'Envía este código a tu amigo', 'Envoyez ce code à votre ami'],
    'start_with_bots': ['Botlarla başla', 'Start with bots', 'Mit Bots starten', 'Empezar con bots', 'Commencer avec des bots'],
    'searching': ['Rakip aranıyor…', 'Looking for rivals…', 'Suche Gegner…', 'Buscando rivales…', 'Recherche d’adversaires…'],
    'online_unavailable': ['Çevrimiçi şu an kullanılamıyor. İnternet bağlantını kontrol et.', 'Online play is unavailable right now. Check your internet connection.', 'Online-Spiel gerade nicht verfügbar. Prüfe deine Internetverbindung.', 'El juego en línea no está disponible. Revisa tu conexión.', 'Le jeu en ligne est indisponible. Vérifiez votre connexion.'],
    'mode_versus': ['Arkadaşla oyna', 'Play with friends', 'Mit Freunden spielen', 'Jugar con amigos', 'Jouer entre amis'],
    'mode_versus_d': ['Aynı cihazda, sırayla', 'On one device, taking turns', 'Auf einem Gerät, abwechselnd', 'En un dispositivo, por turnos', 'Sur un appareil, à tour de rôle'],
    'choose_players': ['Kaç kişi oynayacak?', 'How many players?', 'Wie viele Spieler?', '¿Cuántos jugadores?', 'Combien de joueurs ?'],
    'players_n': ['{n} oyuncu', '{n} players', '{n} Spieler', '{n} jugadores', '{n} joueurs'],
    'player_n': ['Oyuncu {n}', 'Player {n}', 'Spieler {n}', 'Jugador {n}', 'Joueur {n}'],
    'player_wins': ['Oyuncu {n} kazandı!', 'Player {n} wins!', 'Spieler {n} gewinnt!', '¡Gana el jugador {n}!', 'Le joueur {n} gagne !'],
    'draw_title': ['Berabere', 'Draw', 'Unentschieden', 'Empate', 'Match nul'],
    'pass_device': ['Telefonu {p} kişisine ver', 'Pass the device to {p}', 'Gib das Gerät an {p}', 'Pasa el dispositivo a {p}', 'Passez l’appareil à {p}'],
    'tap_when_ready': ['Hazır olunca dokun', 'Tap when ready', 'Tippe, wenn du bereit bist', 'Toca cuando estés listo', 'Touchez quand vous êtes prêt'],
    'remove_ads_desc': ['Oyun arası reklamlar bu uygulamadaki tüm oyunlarda kapanır.', 'Interstitial ads are switched off in every game in this app.', 'Zwischenwerbung wird in allen Spielen dieser App abgeschaltet.', 'Se quitan los anuncios entre partidas en todos los juegos de esta app.', 'Les pubs entre les parties disparaissent dans tous les jeux de l\'appli.'],
    'premium_desc': ['Reklamsız + her gün 3 ücretsiz ipucu + günlük ve görev ödülleri 2 kat + özel temalar ve görünümler + her oyuna hediye altın, ipucu ve elmas.', 'No ads + 3 free hints every day + double daily and mission rewards + exclusive themes and looks + a gift of coins, hints and gems in every game.', 'Werbefrei + täglich 3 Gratis-Tipps + doppelte Tages- und Missionsbelohnungen + exklusive Themen und Looks + Münzen, Tipps und Edelsteine in jedem Spiel.', 'Sin anuncios + 3 pistas gratis al día + recompensas diarias y de misiones dobles + temas y aspectos exclusivos + monedas, pistas y gemas de regalo en cada juego.', 'Sans pub + 3 indices gratuits par jour + récompenses quotidiennes et de missions doublées + thèmes et looks exclusifs + pièces, indices et gemmes offerts dans chaque jeu.'],
    'coins_small': ['Altın kesesi', 'Coin pouch', 'Münzbeutel', 'Bolsa de monedas', 'Bourse'],
    'coins_large': ['Altın sandığı', 'Coin chest', 'Münztruhe', 'Cofre de monedas', 'Coffre'],
    'hint_pack': ['İpucu paketi', 'Hint pack', 'Tipp-Paket', 'Pack de pistas', "Pack d'indices"],
    'starter_pack': ['Başlangıç paketi', 'Starter pack', 'Starterpaket', 'Pack inicial', 'Pack de départ'],
    'store_unavailable': ['Mağaza şu an kullanılamıyor', 'Store unavailable right now', 'Shop nicht verfügbar', 'Tienda no disponible', 'Boutique indisponible'],
    'purchase_ok': ['Satın alma tamamlandı', 'Purchase complete', 'Kauf abgeschlossen', 'Compra completada', 'Achat terminé'],
    'purchase_restored': ['Satın alımlar geri yüklendi', 'Purchases restored', 'Käufe wiederhergestellt', 'Compras restauradas', 'Achats restaurés'],
    'purchase_pending': ['Ödeme bekleniyor', 'Payment pending', 'Zahlung ausstehend', 'Pago pendiente', 'Paiement en attente'],
    'purchase_failed': ['Ödeme başarısız oldu', 'Payment failed', 'Zahlung fehlgeschlagen', 'Pago fallido', 'Paiement échoué'],
    'purchase_canceled': ['Satın alma iptal edildi', 'Purchase canceled', 'Kauf abgebrochen', 'Compra cancelada', 'Achat annulé'],
    'purchase_refunded': ['İade işlendi', 'Refund processed', 'Erstattung verarbeitet', 'Reembolso procesado', 'Remboursement traité'],
    'purchase_unverified': ['Satın alma doğrulanamadı', 'Purchase could not be verified', 'Kauf nicht verifiziert', 'Compra no verificada', 'Achat non vérifié'],
    'purchase_duplicate': ['Bu satın alma zaten işlendi', 'Already processed', 'Bereits verarbeitet', 'Ya procesada', 'Déjà traité'],
    'purchase_unknown': ['Bilinmeyen ürün', 'Unknown product', 'Unbekanntes Produkt', 'Producto desconocido', 'Produit inconnu'],
    'owned': ['Sahipsin', 'Owned', 'Besitzt du', 'Comprado', 'Possédé'],
    'ad_not_ready': ['Reklam şu an hazır değil, sonra tekrar dene', 'Ad not ready, try later', 'Werbung nicht bereit', 'Anuncio no disponible', 'Pub indisponible'],
    'age_title': ['Hoş geldin!', 'Welcome!', 'Willkommen!', '¡Bienvenido!', 'Bienvenue !'],
    'age_question': ['Deneyimini yaşına göre ayarlayalım. Doğum yılın?', "Let's tailor the game to your age. Birth year?", 'Dein Geburtsjahr?', '¿Año de nacimiento?', 'Année de naissance ?'],
    'continue': ['Devam', 'Continue', 'Weiter', 'Continuar', 'Continuer'],
    'consent_title': ['Gizliliğin bizim için önemli', 'Your privacy matters', 'Deine Privatsphäre zählt', 'Tu privacidad importa', 'Votre vie privée compte'],
    'consent_body': ['Oyun internetsiz tamamen oynanır. Ücretsiz kalabilmesi için reklam gösteriyoruz. Kişiselleştirilmiş reklam ve anonim kullanım verisi için iznini isteriz; istediğin zaman Ayarlar > Gizlilik bölümünden değiştirebilirsin.', 'The game is fully playable offline. Ads keep it free. We ask your permission for personalized ads and anonymous usage data; change it any time in Settings > Privacy.', 'Das Spiel funktioniert offline. Werbung hält es kostenlos. Du kannst die Einwilligung jederzeit ändern.', 'El juego funciona sin conexión. Los anuncios lo mantienen gratis. Puedes cambiarlo en Ajustes.', 'Le jeu fonctionne hors ligne. Les pubs le gardent gratuit. Modifiable dans Paramètres.'],
    'accept_all': ['Kabul et', 'Accept', 'Akzeptieren', 'Aceptar', 'Accepter'],
    'essential_only': ['Sadece gerekli olanlar', 'Essential only', 'Nur notwendige', 'Solo esenciales', 'Essentiel uniquement'],
    'safe_mode': ['Güvenli modda başlatıldı: önceki açılışta sorun yaşandı, ilerlemen korunuyor.', 'Started in safe mode after a problem; your progress is safe.', 'Im abgesicherten Modus gestartet.', 'Iniciado en modo seguro.', 'Démarré en mode sans échec.'],
    'save_recovered': ['Kayıt yedekten kurtarıldı', 'Save recovered from backup', 'Spielstand wiederhergestellt', 'Partida recuperada', 'Sauvegarde récupérée'],
    'offline_ok': ['İnternet yok – oyun çevrimdışı devam ediyor', 'Offline – the game keeps working', 'Offline – das Spiel läuft weiter', 'Sin conexión – el juego sigue', 'Hors ligne – le jeu continue'],
    'challenge_n': ['Meydan okuma {n}', 'Challenge {n}', 'Herausforderung {n}', 'Desafío {n}', 'Défi {n}'],
    'done': ['Tamamlandı', 'Done', 'Erledigt', 'Hecho', 'Fait'],
    'stars_total': ['Toplam yıldız', 'Total stars', 'Sterne gesamt', 'Estrellas', 'Étoiles'],
    'levels_done': ['Tamamlanan bölüm', 'Levels completed', 'Level geschafft', 'Niveles completados', 'Niveaux terminés'],
    'play_time': ['Oyun süresi', 'Play time', 'Spielzeit', 'Tiempo de juego', 'Temps de jeu'],
    'win_rate': ['Kazanma oranı', 'Win rate', 'Siegquote', 'Tasa de victoria', 'Taux de victoire'],
    'best_streak': ['En uzun galibiyet serisi', 'Best win streak', 'Längste Siegesserie', 'Mejor racha', 'Meilleure série'],
    'tutorial_title': ['Nasıl oynanır', 'How to play', 'So wird gespielt', 'Cómo jugar', 'Comment jouer'],
    'got_it': ['Anladım', 'Got it', 'Verstanden', 'Entendido', 'Compris'],
    'endless_unlocked_hint': ['Tüm modlar internetsiz oynanır', 'All modes work offline', 'Alle Modi offline', 'Todos los modos sin conexión', 'Tous les modes hors ligne'],
    'out_of_moves': ['Hamlen bitti', 'Out of moves', 'Keine Züge mehr', 'Sin movimientos', 'Plus de coups'],
    'time_up': ['Süre doldu', "Time's up", 'Zeit abgelaufen', 'Se acabó el tiempo', 'Temps écoulé'],
    'continue_ad': ['Reklam izle, devam et', 'Watch an ad to continue', 'Werbung für Weiterspielen', 'Anuncio para continuar', 'Pub pour continuer'],
    'continue_coins': ['{n} altınla devam et', 'Continue for {n} coins', 'Weiter für {n} Münzen', 'Continuar por {n}', 'Continuer pour {n}'],
    'secret_night_owl': ['Gece kuşu', 'Night owl', 'Nachteule', 'Búho nocturno', 'Oiseau de nuit'],
    'secret_early_bird': ['Erkenci kuş', 'Early bird', 'Frühaufsteher', 'Madrugador', 'Lève-tôt'],
    'secret_weekend': ['Hafta sonu keyfi', 'Weekend warrior', 'Wochenendkrieger', 'Guerrero de finde', 'Guerrier du week-end'],
    'secret_new_year': ['Yeni yıl', 'New year', 'Neujahr', 'Año nuevo', 'Nouvel an'],
    'secret_comeback': ['Pes etmeyen', 'Never give up', 'Nie aufgeben', 'Nunca te rindas', 'Jamais abandonner'],
    'secret_stubborn': ['İnatçı', 'Stubborn', 'Stur', 'Testarudo', 'Têtu'],
    'secret_speedster': ['Şimşek', 'Lightning', 'Blitz', 'Relámpago', 'Éclair'],
  };
}
