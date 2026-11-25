/// Onaylı merkez tasarımı ("Oyun Merkezleri · Tasarım Örnekleri 1–3").
///
/// hub.dart'taki [HubConfig] ve [HubServices] aynen kullanılır; yalnızca
/// ana ekran bu dosyadaki koyu, degradeli düzenle çizilir: üst çubuk
/// (menü, aile simgesi, taç), "N Oyun" kahraman alanı, isteğe bağlı arama,
/// filtre çipleri, öne çıkan oyun şeridi, aileye özel kartlar ve alt
/// gezinme (Ana Sayfa · Oyunlar · Görevler · Profil). Bütün sayılar gerçek
/// kayıtlardan hesaplanır.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/strings.dart';
import '../core/telemetry.dart';
import '../online/online_service.dart';
import '../online/online_ui.dart';
import 'adaptive.dart';
import 'app_state.dart';
import 'game_api.dart';
import 'hub.dart';
import 'screens/daily.dart';
import 'screens/profile.dart';
import 'screens/settings.dart';
import 'parental_gate.dart';
import 'screens/shop.dart';
import 'services/ads.dart';
import 'services/audio.dart';
import 'services/cloud_telemetry.dart';
import 'services/prefs_backend.dart';
import 'services/purchases.dart';
import 'studio_apps.dart';
import 'theme.dart';

const Map<String, List<String>> _kTx = {
  'nav_home': ['Ana Sayfa', 'Home', 'Start', 'Inicio', 'Accueil', 'الرئيسية', 'خانه', 'בית', 'ہوم', 'Главная', 'Головна', 'Start', 'Domů', 'Acasă', 'Kezdőlap', 'Αρχική', 'Home', 'Início', 'Home', 'Hem', 'Hjem', 'Hjem', 'Koti', 'ホーム', '홈', '首页', 'होम', 'হোম', 'Beranda', 'Utama', 'หน้าแรก', 'Trang chủ', 'Home'],
  'nav_games': ['Oyunlar', 'Games', 'Spiele', 'Juegos', 'Jeux', 'الألعاب', 'بازی‌ها', 'משחקים', 'گیمز', 'Игры', 'Ігри', 'Gry', 'Hry', 'Jocuri', 'Játékok', 'Παιχνίδια', 'Giochi', 'Jogos', 'Spellen', 'Spel', 'Spil', 'Spill', 'Pelit', 'ゲーム', '게임', '游戏', 'गेम', 'গেম', 'Game', 'Permainan', 'เกม', 'Trò chơi', 'Mga Laro'],
  'nav_tasks': ['Görevler', 'Tasks', 'Aufgaben', 'Misiones', 'Missions', 'المهام', 'مأموریت‌ها', 'משימות', 'مشنز', 'Задания', 'Завдання', 'Zadania', 'Úkoly', 'Misiuni', 'Feladatok', 'Αποστολές', 'Missioni', 'Missões', 'Opdrachten', 'Uppdrag', 'Opgaver', 'Oppdrag', 'Tehtävät', 'ミッション', '미션', '任务', 'मिशन', 'মিশন', 'Misi', 'Misi', 'ภารกิจ', 'Nhiệm vụ', 'Mga Misyon'],
  'nav_profile': ['Profil', 'Profile', 'Profil', 'Perfil', 'Profil', 'الملف', 'پروفایل', 'פרופיל', 'پروفائل', 'Профиль', 'Профіль', 'Profil', 'Profil', 'Profil', 'Profil', 'Προφίλ', 'Profilo', 'Perfil', 'Profiel', 'Profil', 'Profil', 'Profil', 'Profiili', 'プロフィール', '프로필', '个人资料', 'प्रोफ़ाइल', 'প্রোফাইল', 'Profil', 'Profil', 'โปรไฟล์', 'Hồ sơ', 'Profile'],
  'n_games': ['{n} Oyun', '{n} Games', '{n} Spiele', '{n} juegos', '{n} jeux', '{n} لعبة', '{n} بازی', '{n} משחקים', '{n} گیمز', '{n} игр', '{n} ігор', '{n} gier', '{n} her', '{n} jocuri', '{n} játék', '{n} παιχνίδια', '{n} giochi', '{n} jogos', '{n} spellen', '{n} spel', '{n} spil', '{n} spill', '{n} peliä', '{n} ゲーム', '게임 {n}개', '{n} 款游戏', '{n} गेम', '{n}টি গেম', '{n} game', '{n} permainan', '{n} เกม', '{n} trò chơi', '{n} laro'],
  'search': ['Oyun ara…', 'Search games…', 'Spiele suchen…', 'Buscar juegos…', 'Rechercher un jeu…', 'ابحث عن لعبة…', 'جستجوی بازی…', 'חיפוש משחק…', 'گیم تلاش کریں…', 'Поиск игр…', 'Пошук ігор…', 'Szukaj gier…', 'Hledat hry…', 'Caută jocuri…', 'Játék keresése…', 'Αναζήτηση παιχνιδιών…', 'Cerca giochi…', 'Buscar jogos…', 'Spellen zoeken…', 'Sök spel…', 'Søg spil…', 'Søk etter spill…', 'Hae pelejä…', 'ゲームを検索…', '게임 검색…', '搜索游戏…', 'गेम खोजें…', 'গেম খুঁজুন…', 'Cari game…', 'Cari permainan…', 'ค้นหาเกม…', 'Tìm trò chơi…', 'Maghanap ng laro…'],
  'all': ['Tümü', 'All', 'Alle', 'Todos', 'Tout', 'الكل', 'همه', 'הכול', 'سب', 'Все', 'Усі', 'Wszystkie', 'Vše', 'Toate', 'Mind', 'Όλα', 'Tutti', 'Todos', 'Alle', 'Alla', 'Alle', 'Alle', 'Kaikki', 'すべて', '전체', '全部', 'सभी', 'সব', 'Semua', 'Semua', 'ทั้งหมด', 'Tất cả', 'Lahat'],
  'featured': ['Öne Çıkan Oyunlar', 'Featured Games', 'Empfohlene Spiele', 'Juegos destacados', 'Jeux à la une', 'ألعاب مميزة', 'بازی‌های ویژه', 'משחקים מומלצים', 'نمایاں گیمز', 'Избранные игры', 'Рекомендовані ігри', 'Polecane gry', 'Doporučené hry', 'Jocuri recomandate', 'Kiemelt játékok', 'Προτεινόμενα παιχνίδια', 'Giochi in evidenza', 'Jogos em destaque', 'Uitgelichte spellen', 'Utvalda spel', 'Udvalgte spil', 'Utvalgte spill', 'Suositellut pelit', 'おすすめゲーム', '추천 게임', '精选游戏', 'खास गेम', 'বিশেষ গেম', 'Game unggulan', 'Permainan pilihan', 'เกมแนะนำ', 'Trò chơi nổi bật', 'Mga tampok na laro'],
  'popular': ['Popüler Oyunlar', 'Popular Games', 'Beliebte Spiele', 'Juegos populares', 'Jeux populaires', 'ألعاب شائعة', 'بازی‌های محبوب', 'משחקים פופולריים', 'مقبول گیمز', 'Популярные игры', 'Популярні ігри', 'Popularne gry', 'Oblíbené hry', 'Jocuri populare', 'Népszerű játékok', 'Δημοφιλή παιχνίδια', 'Giochi popolari', 'Jogos populares', 'Populaire spellen', 'Populära spel', 'Populære spil', 'Populære spill', 'Suositut pelit', '人気のゲーム', '인기 게임', '热门游戏', 'लोकप्रिय गेम', 'জনপ্রিয় গেম', 'Game populer', 'Permainan popular', 'เกมยอดนิยม', 'Trò chơi phổ biến', 'Mga sikat na laro'],
  'categories': ['Kategoriler', 'Categories', 'Kategorien', 'Categorías', 'Catégories', 'الفئات', 'دسته‌ها', 'קטגוריות', 'زمرے', 'Категории', 'Категорії', 'Kategorie', 'Kategorie', 'Categorii', 'Kategóriák', 'Κατηγορίες', 'Categorie', 'Categorias', 'Categorieën', 'Kategorier', 'Kategorier', 'Kategorier', 'Kategoriat', 'カテゴリー', '카테고리', '分类', 'श्रेणियाँ', 'বিভাগ', 'Kategori', 'Kategori', 'หมวดหมู่', 'Danh mục', 'Mga Kategorya'],
  'quest_title': ['Haftalık Görev', 'Weekly Quest', 'Wochenaufgabe', 'Misión semanal', 'Quête de la semaine', 'مهمة الأسبوع', 'مأموریت هفته', 'משימה שבועית', 'ہفتہ وار مشن', 'Задание недели', 'Завдання тижня', 'Zadanie tygodnia', 'Týdenní úkol', 'Misiunea săptămânii', 'Heti feladat', 'Εβδομαδιαία αποστολή', 'Missione settimanale', 'Missão semanal', 'Weekopdracht', 'Veckans uppdrag', 'Ugens opgave', 'Ukens oppdrag', 'Viikon tehtävä', '今週のミッション', '주간 미션', '每周任务', 'साप्ताहिक मिशन', 'সাপ্তাহিক মিশন', 'Misi mingguan', 'Misi mingguan', 'ภารกิจประจำสัปดาห์', 'Nhiệm vụ tuần', 'Lingguhang misyon'],
  'quest_body': ['{n} farklı oyun oyna!', 'Play {n} different games!', 'Spiele {n} verschiedene Spiele!', '¡Juega a {n} juegos distintos!', 'Joue à {n} jeux différents !', 'العب {n} ألعاب مختلفة!', '{n} بازی متفاوت بازی کن!', 'שחקו ב-{n} משחקים שונים!', '{n} مختلف گیمز کھیلیں!', 'Сыграй в {n} разные игры!', 'Зіграй у {n} різні ігри!', 'Zagraj w {n} różne gry!', 'Zahraj si {n} různé hry!', 'Joacă {n} jocuri diferite!', 'Játssz {n} különböző játékkal!', 'Παίξε {n} διαφορετικά παιχνίδια!', 'Gioca a {n} giochi diversi!', 'Jogue {n} jogos diferentes!', 'Speel {n} verschillende spellen!', 'Spela {n} olika spel!', 'Spil {n} forskellige spil!', 'Spill {n} forskjellige spill!', 'Pelaa {n} eri peliä!', '{n}種類のゲームを遊ぼう!', '{n}개의 다른 게임을 플레이하세요!', '玩{n}款不同的游戏!', '{n} अलग गेम खेलें!', '{n}টি আলাদা গেম খেলুন!', 'Mainkan {n} game berbeda!', 'Main {n} permainan berbeza!', 'เล่น {n} เกมที่ต่างกัน!', 'Chơi {n} trò chơi khác nhau!', 'Maglaro ng {n} magkakaibang laro!'],
  'claim': ['Ödülü al', 'Claim reward', 'Belohnung holen', 'Reclamar premio', 'Récupérer', 'استلم الجائزة', 'دریافت جایزه', 'קבלו פרס', 'انعام لیں', 'Забрать награду', 'Забрати нагороду', 'Odbierz nagrodę', 'Vyzvednout odměnu', 'Revendică', 'Jutalom átvétele', 'Λήψη ανταμοιβής', 'Riscatta premio', 'Resgatar prêmio', 'Beloning ophalen', 'Hämta belöning', 'Hent belønning', 'Hent belønning', 'Lunasta palkinto', '報酬を受け取る', '보상 받기', '领取奖励', 'इनाम लें', 'পুরস্কার নিন', 'Klaim hadiah', 'Tuntut ganjaran', 'รับรางวัล', 'Nhận thưởng', 'Kunin ang gantimpala'],
  'progress_title': ['İlerleme Durumun', 'Your Progress', 'Dein Fortschritt', 'Tu progreso', 'Ta progression', 'تقدّمك', 'پیشرفت تو', 'ההתקדמות שלך', 'آپ کی پیش رفت', 'Твой прогресс', 'Твій прогрес', 'Twoje postępy', 'Tvůj postup', 'Progresul tău', 'Haladásod', 'Η πρόοδός σου', 'I tuoi progressi', 'Seu progresso', 'Jouw voortgang', 'Dina framsteg', 'Dine fremskridt', 'Din fremgang', 'Edistymisesi', 'あなたの進み具合', '진행 상황', '你的进度', 'आपकी प्रगति', 'আপনার অগ্রগতি', 'Progresmu', 'Kemajuan anda', 'ความคืบหน้าของคุณ', 'Tiến độ của bạn', 'Iyong progreso'],
  'progress_body': ['Bu merkezde denediğin oyunlar', 'Games you\'ve tried in this hub', 'Hier ausprobierte Spiele', 'Juegos que has probado aquí', 'Jeux essayés ici', 'الألعاب التي جرّبتها هنا', 'بازی‌هایی که اینجا امتحان کردی', 'משחקים שניסית כאן', 'یہاں آزمائے گئے گیمز', 'Игры, которые ты попробовал', 'Ігри, які ти спробував', 'Wypróbowane tu gry', 'Hry, které jsi tu zkusil', 'Jocuri încercate aici', 'Itt kipróbált játékok', 'Παιχνίδια που δοκίμασες εδώ', 'Giochi provati qui', 'Jogos que você experimentou aqui', 'Spellen die je hier probeerde', 'Spel du har provat här', 'Spil du har prøvet her', 'Spill du har prøvd her', 'Täällä kokeilemasi pelit', 'ここで遊んだゲーム', '여기서 해본 게임', '你在这里玩过的游戏', 'यहाँ आज़माए गए गेम', 'এখানে খেলা গেম', 'Game yang sudah dicoba di sini', 'Permainan yang telah dicuba di sini', 'เกมที่คุณลองแล้วที่นี่', 'Trò chơi bạn đã thử ở đây', 'Mga larong nasubukan mo rito'],
  'gift_title': ['Günlük Ödül', 'Daily Reward', 'Tagesbelohnung', 'Premio diario', 'Récompense du jour', 'مكافأة يومية', 'جایزه روزانه', 'פרס יומי', 'روزانہ انعام', 'Ежедневная награда', 'Щоденна нагорода', 'Codzienna nagroda', 'Denní odměna', 'Recompensa zilnică', 'Napi jutalom', 'Ημερήσια ανταμοιβή', 'Premio giornaliero', 'Recompensa diária', 'Dagelijkse beloning', 'Daglig belöning', 'Daglig belønning', 'Daglig belønning', 'Päivän palkinto', 'デイリー報酬', '일일 보상', '每日奖励', 'दैनिक इनाम', 'দৈনিক পুরস্কার', 'Hadiah harian', 'Ganjaran harian', 'รางวัลประจำวัน', 'Phần thưởng hằng ngày', 'Pang-araw-araw na gantimpala'],
  'gift_body': ['Bugün oyna, ödülünü al!', 'Play today, claim your reward!', 'Spiel heute und hol dir deine Belohnung!', '¡Juega hoy y recibe tu premio!', 'Joue aujourd\'hui, récupère ta récompense !', 'العب اليوم واحصل على جائزتك!', 'امروز بازی کن، جایزه‌ات را بگیر!', 'שחקו היום וקבלו פרס!', 'آج کھیلیں، انعام لیں!', 'Играй сегодня — получи награду!', 'Грай сьогодні — отримай нагороду!', 'Zagraj dziś i odbierz nagrodę!', 'Hraj dnes a vyzvedni si odměnu!', 'Joacă azi, ia-ți recompensa!', 'Játssz ma, vedd át a jutalmad!', 'Παίξε σήμερα, πάρε την ανταμοιβή σου!', 'Gioca oggi, ritira il premio!', 'Jogue hoje e pegue sua recompensa!', 'Speel vandaag, haal je beloning!', 'Spela idag, hämta din belöning!', 'Spil i dag, hent din belønning!', 'Spill i dag, hent belønningen!', 'Pelaa tänään, lunasta palkinto!', '今日遊んで報酬をもらおう!', '오늘 플레이하고 보상을 받으세요!', '今天玩，领奖励!', 'आज खेलें, इनाम लें!', 'আজ খেলুন, পুরস্কার নিন!', 'Main hari ini, ambil hadiahmu!', 'Main hari ini, tuntut ganjaran!', 'เล่นวันนี้ รับรางวัล!', 'Chơi hôm nay, nhận thưởng!', 'Maglaro ngayon, kunin ang gantimpala!'],
  'gift_done': ['Yarın yine gel!', 'Come back tomorrow!', 'Komm morgen wieder!', '¡Vuelve mañana!', 'Reviens demain !', 'عُد غدًا!', 'فردا دوباره بیا!', 'חזרו מחר!', 'کل دوبارہ آئیں!', 'Возвращайся завтра!', 'Повертайся завтра!', 'Wróć jutro!', 'Vrať se zítra!', 'Revino mâine!', 'Gyere vissza holnap!', 'Έλα ξανά αύριο!', 'Torna domani!', 'Volte amanhã!', 'Kom morgen terug!', 'Kom tillbaka i morgon!', 'Kom tilbage i morgen!', 'Kom tilbake i morgen!', 'Palaa huomenna!', 'また明日!', '내일 다시 오세요!', '明天再来!', 'कल फिर आएँ!', 'কাল আবার আসুন!', 'Kembali besok!', 'Kembali esok!', 'กลับมาพรุ่งนี้!', 'Mai quay lại nhé!', 'Bumalik bukas!'],
  'challenge_title': ['Günün Meydan Okuması', 'Daily Challenge', 'Tägliche Herausforderung', 'Reto del día', 'Défi du jour', 'تحدي اليوم', 'چالش روز', 'האתגר היומי', 'آج کا چیلنج', 'Испытание дня', 'Виклик дня', 'Wyzwanie dnia', 'Výzva dne', 'Provocarea zilei', 'A nap kihívása', 'Η πρόκληση της ημέρας', 'Sfida del giorno', 'Desafio do dia', 'Uitdaging van de dag', 'Dagens utmaning', 'Dagens udfordring', 'Dagens utfordring', 'Päivän haaste', '今日のチャレンジ', '오늘의 도전', '每日挑战', 'आज की चुनौती', 'আজকের চ্যালেঞ্জ', 'Tantangan harian', 'Cabaran harian', 'ความท้าทายประจำวัน', 'Thử thách hôm nay', 'Hamon ng araw'],
  'challenge_body': ['3 oyunla zihnini test et!', 'Test your mind with 3 games!', 'Teste deinen Kopf mit 3 Spielen!', '¡Pon a prueba tu mente con 3 juegos!', 'Teste ton esprit avec 3 jeux !', 'اختبر عقلك بثلاث ألعاب!', 'ذهنت را با ۳ بازی محک بزن!', 'בחנו את המוח ב-3 משחקים!', '3 گیمز سے ذہن آزمائیں!', 'Проверь ум в 3 играх!', 'Перевір розум у 3 іграх!', 'Sprawdź umysł w 3 grach!', 'Otestuj mysl ve 3 hrách!', 'Testează-ți mintea cu 3 jocuri!', 'Teszteld az elméd 3 játékkal!', 'Δοκίμασε το μυαλό σου με 3 παιχνίδια!', 'Metti alla prova la mente con 3 giochi!', 'Teste sua mente com 3 jogos!', 'Test je brein met 3 spellen!', 'Testa hjärnan med 3 spel!', 'Test hjernen med 3 spil!', 'Test hjernen med 3 spill!', 'Testaa mielesi 3 pelillä!', '3つのゲームで頭を試そう!', '3가지 게임으로 두뇌를 시험하세요!', '用3款游戏测试大脑!', '3 गेम से दिमाग परखें!', '৩টি গেমে মন পরীক্ষা করুন!', 'Uji pikiranmu dengan 3 game!', 'Uji minda dengan 3 permainan!', 'ทดสอบสมองด้วย 3 เกม!', 'Thử trí não với 3 trò chơi!', 'Subukin ang isip sa 3 laro!'],
  'stats_title': ['İstatistiklerin', 'Your Stats', 'Deine Statistik', 'Tus estadísticas', 'Tes statistiques', 'إحصاءاتك', 'آمار تو', 'הסטטיסטיקה שלך', 'آپ کے اعداد و شمار', 'Твоя статистика', 'Твоя статистика', 'Twoje statystyki', 'Tvoje statistiky', 'Statisticile tale', 'Statisztikáid', 'Τα στατιστικά σου', 'Le tue statistiche', 'Suas estatísticas', 'Jouw statistieken', 'Din statistik', 'Din statistik', 'Din statistikk', 'Tilastosi', 'あなたの記録', '내 통계', '你的统计', 'आपके आँकड़े', 'আপনার পরিসংখ্যান', 'Statistikmu', 'Statistik anda', 'สถิติของคุณ', 'Thống kê của bạn', 'Iyong istatistika'],
  'contest_title': ['Haftalık Yarışma', 'Weekly Contest', 'Wochenwettbewerb', 'Competición semanal', 'Concours de la semaine', 'مسابقة أسبوعية', 'مسابقه هفتگی', 'תחרות שבועית', 'ہفتہ وار مقابلہ', 'Турнир недели', 'Турнір тижня', 'Turniej tygodnia', 'Týdenní soutěž', 'Concursul săptămânii', 'Heti verseny', 'Εβδομαδιαίος διαγωνισμός', 'Gara settimanale', 'Competição semanal', 'Wekelijkse wedstrijd', 'Veckans tävling', 'Ugens konkurrence', 'Ukens konkurranse', 'Viikon kilpailu', '週間コンテスト', '주간 대회', '每周竞赛', 'साप्ताहिक प्रतियोगिता', 'সাপ্তাহিক প্রতিযোগিতা', 'Kontes mingguan', 'Pertandingan mingguan', 'การแข่งขันประจำสัปดาห์', 'Cuộc thi tuần', 'Lingguhang paligsahan'],
  'contest_body': ['En yüksek puanı topla, liderliğe yüksel!', 'Score high and climb the leaderboard!', 'Hol Punkte und steig in der Rangliste auf!', '¡Suma puntos y sube en la clasificación!', 'Marque des points et grimpe au classement !', 'اجمع النقاط واصعد في الترتيب!', 'امتیاز بگیر و در جدول بالا برو!', 'צברו נקודות וטפסו בטבלה!', 'زیادہ اسکور کریں اور اوپر جائیں!', 'Набирай очки и поднимайся в рейтинге!', 'Набирай очки й піднімайся в рейтингу!', 'Zdobywaj punkty i wspinaj się w rankingu!', 'Sbírej body a stoupej v žebříčku!', 'Adună puncte și urcă în clasament!', 'Gyűjts pontot, és lépj feljebb a ranglistán!', 'Μάζεψε πόντους και ανέβα στην κατάταξη!', 'Fai punti e sali in classifica!', 'Some pontos e suba no ranking!', 'Scoor punten en klim in de ranglijst!', 'Samla poäng och klättra på topplistan!', 'Saml point og klatr på ranglisten!', 'Samle poeng og klatre på listen!', 'Kerää pisteitä ja nouse listalla!', '高得点でランキング上位へ!', '점수를 올려 순위를 높이세요!', '拿高分，冲上排行榜!', 'अंक जुटाएँ, रैंकिंग में ऊपर जाएँ!', 'পয়েন্ট তুলুন, র‍্যাংকিংয়ে উঠুন!', 'Kumpulkan poin dan naik peringkat!', 'Kumpul mata dan naik kedudukan!', 'ทำคะแนนและไต่อันดับ!', 'Ghi điểm và leo bảng xếp hạng!', 'Mag-ipon ng puntos at umakyat sa ranggo!'],
  'points': ['Puanın', 'Your points', 'Deine Punkte', 'Tus puntos', 'Tes points', 'نقاطك', 'امتیاز تو', 'הנקודות שלך', 'آپ کے پوائنٹس', 'Твои очки', 'Твої очки', 'Twoje punkty', 'Tvé body', 'Punctele tale', 'Pontjaid', 'Οι πόντοι σου', 'I tuoi punti', 'Seus pontos', 'Jouw punten', 'Dina poäng', 'Dine point', 'Dine poeng', 'Pisteesi', 'ポイント', '내 점수', '你的积分', 'आपके अंक', 'আপনার পয়েন্ট', 'Poinmu', 'Mata anda', 'คะแนนของคุณ', 'Điểm của bạn', 'Iyong puntos'],
  'rank': ['Sıralaman', 'Your rank', 'Dein Rang', 'Tu puesto', 'Ton rang', 'ترتيبك', 'رتبه تو', 'הדירוג שלך', 'آپ کی رینک', 'Твоё место', 'Твоє місце', 'Twoja pozycja', 'Tvé pořadí', 'Locul tău', 'Helyezésed', 'Η θέση σου', 'La tua posizione', 'Sua posição', 'Jouw rang', 'Din placering', 'Din placering', 'Din plassering', 'Sijoituksesi', '順位', '내 순위', '你的排名', 'आपकी रैंक', 'আপনার র‍্যাংক', 'Peringkatmu', 'Kedudukan anda', 'อันดับของคุณ', 'Thứ hạng của bạn', 'Iyong ranggo'],
  'play_now': ['Hemen Oyna', 'Play Now', 'Jetzt spielen', 'Jugar ahora', 'Jouer maintenant', 'العب الآن', 'همین حالا بازی کن', 'שחקו עכשיו', 'ابھی کھیلیں', 'Играть сейчас', 'Грати зараз', 'Graj teraz', 'Hrát hned', 'Joacă acum', 'Játék most', 'Παίξε τώρα', 'Gioca ora', 'Jogar agora', 'Nu spelen', 'Spela nu', 'Spil nu', 'Spill nå', 'Pelaa nyt', '今すぐ遊ぶ', '지금 플레이', '立即开始', 'अभी खेलें', 'এখনই খেলুন', 'Main sekarang', 'Main sekarang', 'เล่นเลย', 'Chơi ngay', 'Maglaro na'],
  'campaign': ['Sefer İlerlemesi', 'Campaign Progress', 'Feldzugsfortschritt', 'Progreso de campaña', 'Progression de campagne', 'تقدم الحملة', 'پیشرفت لشکرکشی', 'התקדמות המסע', 'مہم کی پیش رفت', 'Прогресс похода', 'Прогрес походу', 'Postęp kampanii', 'Postup tažení', 'Progresul campaniei', 'Hadjárat állása', 'Πρόοδος εκστρατείας', 'Progresso campagna', 'Progresso da campanha', 'Voortgang veldtocht', 'Fälttågets framsteg', 'Felttogets fremskridt', 'Felttogets fremgang', 'Sotaretken eteneminen', '遠征の進行', '원정 진행도', '远征进度', 'अभियान की प्रगति', 'অভিযানের অগ্রগতি', 'Kemajuan kampanye', 'Kemajuan kempen', 'ความคืบหน้าการเดินทัพ', 'Tiến độ chiến dịch', 'Progreso ng kampanya'],
  'n_of_m': ['{n} / {m} Bölüm', '{n} / {m} Sections', '{n} / {m} Bereiche', '{n} / {m} secciones', '{n} / {m} sections', '{n} / {m} أقسام', '{n} / {m} بخش', '{n} / {m} פרקים', '{n} / {m} حصے', '{n} / {m} разделов', '{n} / {m} розділів', '{n} / {m} działów', '{n} / {m} oddílů', '{n} / {m} secțiuni', '{n} / {m} szakasz', '{n} / {m} ενότητες', '{n} / {m} sezioni', '{n} / {m} seções', '{n} / {m} onderdelen', '{n} / {m} avsnitt', '{n} / {m} afsnit', '{n} / {m} deler', '{n} / {m} osiota', '{n} / {m} セクション', '{n} / {m} 구역', '{n} / {m} 部分', '{n} / {m} भाग', '{n} / {m} অংশ', '{n} / {m} bagian', '{n} / {m} bahagian', '{n} / {m} ส่วน', '{n} / {m} phần', '{n} / {m} bahagi'],
  'level': ['Seviye', 'Level', 'Stufe', 'Nivel', 'Niveau', 'المستوى', 'سطح', 'רמה', 'لیول', 'Уровень', 'Рівень', 'Poziom', 'Úroveň', 'Nivel', 'Szint', 'Επίπεδο', 'Livello', 'Nível', 'Niveau', 'Nivå', 'Niveau', 'Nivå', 'Taso', 'レベル', '레벨', '等级', 'स्तर', 'লেভেল', 'Level', 'Tahap', 'ระดับ', 'Cấp', 'Antas'],
  'growth': ['Gelişim', 'Growth', 'Entwicklung', 'Crecimiento', 'Développement', 'التطور', 'پیشرفت', 'התפתחות', 'ترقی', 'Развитие', 'Розвиток', 'Rozwój', 'Rozvoj', 'Dezvoltare', 'Fejlődés', 'Ανάπτυξη', 'Crescita', 'Crescimento', 'Groei', 'Utveckling', 'Udvikling', 'Utvikling', 'Kehitys', '発展', '성장', '发展', 'विकास', 'উন্নয়ন', 'Perkembangan', 'Perkembangan', 'การเติบโต', 'Phát triển', 'Pag-unlad'],
  'change_game': ['Oyun değiştir', 'Change game', 'Spiel wechseln', 'Cambiar juego', 'Changer de jeu', 'تغيير اللعبة', 'تغییر بازی', 'החלפת משחק', 'گیم بدلیں', 'Сменить игру', 'Змінити гру', 'Zmień grę', 'Změnit hru', 'Schimbă jocul', 'Játék váltása', 'Αλλαγή παιχνιδιού', 'Cambia gioco', 'Trocar jogo', 'Ander spel', 'Byt spel', 'Skift spil', 'Bytt spill', 'Vaihda peliä', 'ゲームを変更', '게임 변경', '切换游戏', 'गेम बदलें', 'গেম বদলান', 'Ganti game', 'Tukar permainan', 'เปลี่ยนเกม', 'Đổi trò chơi', 'Palitan ang laro'],
  'more_apps': ['Diğer uygulamalarımız', 'More of our apps', 'Weitere Apps', 'Más apps nuestras', 'Nos autres applis', 'المزيد من تطبيقاتنا', 'برنامه‌های دیگر ما', 'עוד אפליקציות שלנו', 'ہماری مزید ایپس', 'Другие наши приложения', 'Інші наші застосунки', 'Inne nasze aplikacje', 'Další naše aplikace', 'Alte aplicații ale noastre', 'További alkalmazásaink', 'Περισσότερες εφαρμογές μας', 'Altre nostre app', 'Mais apps nossos', 'Meer van onze apps', 'Fler av våra appar', 'Flere af vores apps', 'Flere av våre apper', 'Muut sovelluksemme', 'ほかのアプリ', '다른 앱', '更多应用', 'हमारे और ऐप्स', 'আমাদের আরও অ্যাপ', 'Aplikasi kami lainnya', 'Lagi aplikasi kami', 'แอปอื่นของเรา', 'Ứng dụng khác của chúng tôi', 'Iba pa naming app'],
};

/// Ana ekranda kahraman alanının altında sırayla gösterilen bloklar.
enum ApprovedBlock {
  /// "Oyun ara…" alanı.
  search,

  /// Tümü + merkez bölümleri; seçilen bölüm öne çıkanlar şeridini süzer.
  chips,

  /// Öne çıkan oyunlar şeridi (sayfa noktalarıyla).
  featured,

  /// Bölümleri açan "Kategoriler" çipleri.
  categories,

  /// Bu hafta N farklı oyun oyna (ödüllü).
  weeklyQuest,

  /// Merkezde denenen oyunların yüzdesi.
  progress,

  /// Günlük ödül kartı.
  dailyReward,

  /// Günün meydan okuması (bir oyunu açar).
  dailyChallenge,

  /// Bölüm başına başarı yüzdeleri.
  brainStats,

  /// Haftalık yarışma kartı.
  weeklyContest,

  /// Renkli kategori kutuları.
  categoryTiles,

  /// Puan ve sıralama satırı.
  scoreRank,

  /// Büyük "Hemen Oyna" düğmesi.
  playNow,

  /// Bölüm (sefer) ilerlemesi.
  campaign,

  /// Altın · elmas · can çubuğu.
  currency,

  /// Seviye ve gelişim çubuğu.
  growth,
}

/// Renkli kategori kutusu (ör. Bilgi: Genel Kültür, Bilim, Tarih…).
class ApprovedCategory {
  final List<String> title;
  final String? asset;
  final IconData icon;
  final Color color;
  final List<String> ids;
  const ApprovedCategory({required this.title, this.asset, required this.icon, required this.color, required this.ids});
}

/// Bir merkezin onaylı görünümü: renkler, görseller ve blok sırası.
class ApprovedHubStyle {
  /// Arka plan degradesi (yukarıdan aşağı).
  final List<Color> background;

  /// Seçili sekme, çip ve "Tümü" bağlantısı rengi.
  final Color accent;

  /// Kart ve kutu zemini.
  final Color card;

  /// Oyna düğmesi rengi.
  final Color play;

  /// "N Oyun" sayısının rengi.
  final Color number;

  /// Kahraman görseli (merkezin kendi varlığı, ör. assets/design/hero.png).
  final String? heroAsset;

  /// "N Oyun"un altında aile adı da büyük yazılsın mı.
  final bool heroTitle;

  final List<ApprovedBlock> blocks;

  /// 'featured' ya da 'popular' başlığı.
  final String featuredKey;

  /// Öne çıkanlar (gameId); boşsa bölüm sırası.
  final List<String> featured;

  /// gameId → kutu görseli (varlık yolu).
  final Map<String, String> tileArt;

  final int tilesPerPage;
  final List<String>? growthLabel;
  final List<String>? categoriesLabel;
  final List<ApprovedCategory> categoryTiles;
  final String? challengeGameId;
  final int questTarget;

  const ApprovedHubStyle({
    this.background = const [Color(0xFF2A1A6E), Color(0xFF15104A), Color(0xFF0B0A2E)],
    this.accent = const Color(0xFF2FD3F5),
    this.card = const Color(0xFF3A2290),
    this.play = const Color(0xFF1FA2F2),
    this.number = Colors.white,
    this.heroAsset,
    this.heroTitle = false,
    this.blocks = const [ApprovedBlock.search, ApprovedBlock.featured],
    this.featuredKey = 'featured',
    this.featured = const [],
    this.tileArt = const {},
    this.tilesPerPage = 3,
    this.growthLabel,
    this.categoriesLabel,
    this.categoryTiles = const [],
    this.challengeGameId,
    this.questTarget = 3,
  });
}

String _tx(String key, String lang, [Map<String, Object> p = const {}]) {
  var s = Strings.pick(_kTx[key] ?? [key], lang);
  p.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String _compact(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Onaylı tasarımlı merkezin `main()` girişi.
void bootstrapApprovedHub(HubConfig hub, ApprovedHubStyle style, {String privacyUrl = ''}) {
  hubPrivacyUrl = privacyUrl.isNotEmpty
      ? privacyUrl
      : 'https://github.com/taktemurr-ops/${hub.hubId}/blob/main/PRIVACY.md';
  final startWatch = Stopwatch()..start();
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final backend = await PrefsBackend.create();
    final errors = ErrorJournal(backend);
    await errors.beginLaunch();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      errors.record(ErrorCategory.crash, details.exceptionAsString());
      CloudTelemetry.recordFlutter(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      errors.record(ErrorCategory.crash, error, fatal: true);
      CloudTelemetry.recordError(error, stack, fatal: true);
      return true;
    };
    final emergency = EmergencyConfig();
    try {
      final raw = await rootBundle.loadString('assets/config/emergency.json');
      emergency.merge(Map<String, Object?>.from(jsonDecode(raw) as Map));
    } catch (_) {/* isteğe bağlı dosya */}
    if (errors.safeMode) emergency.adsDisabled = true;
    final analytics = AnalyticsQueue(backend);
    await analytics.restore();
    final perf = PerformanceMonitor();
    final services = HubServices(
      backend: backend,
      errors: errors,
      analytics: analytics,
      emergency: emergency,
      perf: perf,
      ads: AdsService.create(),
      purchases: PurchaseService.create(),
      audio: AudioService(),
    );
    await services.loadShared();
    services.registerTransfer(hub.allGames);
    runApp(ApprovedHubApp(hub: hub, style: style, services: services));
    unawaited(CloudTelemetry.init(crashReports: true, measurement: false));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Adaptive.applyOrientationPolicy();
      perf.recordStartup(startWatch.elapsedMilliseconds);
      await errors.launchSucceeded();
    });
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}

class ApprovedHubApp extends StatefulWidget {
  final HubConfig hub;
  final ApprovedHubStyle style;
  final HubServices services;
  const ApprovedHubApp({super.key, required this.hub, required this.style, required this.services});

  @override
  State<ApprovedHubApp> createState() => _ApprovedHubAppState();
}

class _ApprovedHubAppState extends State<ApprovedHubApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => Adaptive.applyOrientationPolicy();

  @override
  Widget build(BuildContext context) {
    final lang = Strings.pickLanguage(PlatformDispatcher.instance.locale.languageCode);
    final theme = buildTheme(widget.style.accent, Brightness.dark);
    return MaterialApp(
      title: widget.hub.localized(widget.hub.title, lang),
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      locale: Locale(lang),
      supportedLocales: Strings.languages.map(Locale.new).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.services.consent == null
          ? _ConsentPage(
              hub: widget.hub,
              style: widget.style,
              lang: lang,
              onChoice: (all) async {
                await widget.services.setConsent(all);
                if (mounted) setState(() {});
              },
            )
          : ApprovedHubShell(hub: widget.hub, style: widget.style, services: widget.services, lang: lang),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  final HubConfig hub;
  final ApprovedHubStyle style;
  final String lang;
  final Future<void> Function(bool acceptAll) onChoice;
  const _ConsentPage({required this.hub, required this.style, required this.lang, required this.onChoice});

  @override
  Widget build(BuildContext context) {
    final t = Strings(lang);
    return Scaffold(
      body: _Backdrop(
        style: style,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Icon(hub.icon, size: 96, color: style.accent),
                  const SizedBox(height: 12),
                  Text(hub.localized(hub.title, lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  Text(t.t('consent_title'),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(t.t('consent_body'), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: () => onChoice(true), child: Text(t.t('accept_all'))),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: () => onChoice(false), child: Text(t.t('essential_only'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Koyu degrade zemin.
class _Backdrop extends StatelessWidget {
  final ApprovedHubStyle style;
  final Widget child;
  const _Backdrop({required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: style.background),
      ),
      child: child,
    );
  }
}

/// Bir oyunun merkez düzeyindeki özeti (ana ekran kartları için).
class _Sum {
  final int completed;
  final int stars;
  final int xp;
  final String day;
  const _Sum(this.completed, this.stars, this.xp, this.day);

  Map<String, Object> toJson() => {'c': completed, 's': stars, 'x': xp, 'd': day};

  static _Sum? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _Sum((m['c'] as num?)?.toInt() ?? 0, (m['s'] as num?)?.toInt() ?? 0, (m['x'] as num?)?.toInt() ?? 0,
          m['d'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }
}

class ApprovedHubShell extends StatefulWidget {
  final HubConfig hub;
  final ApprovedHubStyle style;
  final HubServices services;
  final String lang;
  const ApprovedHubShell(
      {super.key, required this.hub, required this.style, required this.services, required this.lang});

  @override
  State<ApprovedHubShell> createState() => _ApprovedHubShellState();
}

class _ApprovedHubShellState extends State<ApprovedHubShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _pager = PageController();
  int _tab = 0;
  int _page = 0;
  String _query = '';
  int _chip = -1;
  String? _opening;
  final Map<String, _Sum> _sums = {};
  AppState? _anchor;
  String _giftDay = '';
  String _questWeek = '';

  HubConfig get hub => widget.hub;
  ApprovedHubStyle get style => widget.style;
  String get lang => widget.lang;
  String tx(String k, [Map<String, Object> p = const {}]) => _tx(k, lang, p);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_firstRunGuide());
      unawaited(OnlineHost.attach(context, Strings(lang), (id) {
        final g = _game(id);
        return g == null ? id : hub.localized(g.title, lang);
      }, _openFor));
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  GameConfig? _game(String id) {
    for (final g in hub.allGames) {
      if (g.gameId == id) return g;
    }
    return null;
  }

  Future<void> _load() async {
    final b = widget.services.backend;
    for (final g in hub.allGames) {
      final s = _Sum.parse(await b.read('hub.sum.${g.gameId}'));
      if (s != null) _sums[g.gameId] = s;
    }
    _giftDay = await b.read('hub.gift') ?? '';
    _questWeek = await b.read('hub.quest') ?? '';
    final last = await b.read('hub.last');
    final feat = _featuredGames(null);
    final anchor = _game(last ?? '') ?? (feat.isNotEmpty ? feat.first : (hub.allGames.isNotEmpty ? hub.allGames.first : null));
    if (anchor != null) {
      final st = await widget.services.stateFor(anchor);
      if (mounted) _anchor = st;
    }
    if (mounted) setState(() {});
  }

  // ---- Oyun açma -------------------------------------------------------------

  Future<void> _open(GameConfig g) async {
    if (_opening != null) return;
    setState(() => _opening = g.gameId);
    try {
      final state = await widget.services.stateFor(g);
      if (!mounted) return;
      state.onResumed();
      widget.services.active = state;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => HubGamePage(state: state, backLabel: tx('nav_games'), cover: hub.coverFor(g.gameId)),
      ));
      widget.services.active = null;
      state.onPaused();
      await _record(g, state);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Future<void> _record(GameConfig g, AppState st) async {
    final s = st.save;
    final sum = _Sum(s.completedLevels, s.totalStars, s.totalXp, _day(DateTime.now()));
    _sums[g.gameId] = sum;
    _anchor = st;
    final b = widget.services.backend;
    await b.write('hub.sum.${g.gameId}', jsonEncode(sum.toJson()));
    await b.write('hub.last', g.gameId);
  }

  Future<bool> _openFor(String gameId, Future<void> Function(BuildContext, AppState) action) async {
    final g = _game(gameId);
    if (g == null || !mounted) return false;
    Navigator.of(context).popUntil((r) => r.isFirst);
    final state = await widget.services.stateFor(g);
    state.pendingOnline = (c) => action(c, state);
    if (!mounted) return false;
    _opening = null;
    unawaited(_open(g));
    return true;
  }

  void _openSection(List<String> title, List<String> ids) {
    final games = [for (final id in ids) if (_game(id) != null) _game(id)!];
    if (games.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _GameListPage(
        title: hub.localized(title, lang),
        style: style,
        games: games,
        tile: (g) => _tile(g),
      ),
    ));
  }

  // ---- İlk açılış ------------------------------------------------------------

  static const _guideKey = 'hub.guide.v1';

  Future<void> _firstRunGuide() async {
    final backend = widget.services.backend;
    if (await backend.read(_guideKey) != null || !mounted) return;
    await backend.write(_guideKey, '1');
    final s = Strings(lang);
    final picks = <GameConfig>[
      for (final id in hub.starters)
        if (_game(id) != null) _game(id)!,
    ];
    if (picks.isEmpty) picks.addAll(_featuredGames(null).take(3));
    if (!mounted) return;
    final chosen = await showModalBottomSheet<GameConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        key: const ValueKey('hub-guide'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(s.t('hub_welcome'),
                style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(s.t('hub_welcome_body', {'n': hub.allGames.length})),
            const SizedBox(height: 12),
            for (final g in picks.take(3))
              Card(
                child: ListTile(
                  leading: _art(g, 48),
                  title: Text(hub.localized(g.title, lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(hub.localized(g.tagline, lang), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => Navigator.pop(c, g),
                ),
              ),
            const SizedBox(height: 12),
            Text(s.t('hub_tips'), style: Theme.of(c).textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(c), child: Text(s.t('hub_browse'))),
          ]),
        ),
      ),
    );
    if (chosen != null && mounted) unawaited(_open(chosen));
  }

  // ---- Veri ------------------------------------------------------------------

  List<GameConfig> _sectionGames(int i) {
    if (i < 0 || i >= hub.sections.length) return const [];
    final out = <GameConfig>[];
    for (final id in hub.sections[i].ids) {
      final g = _game(id);
      if (g != null) {
        out.add(g);
      } else {
        for (final gr in hub.groups) {
          if (gr.id == id) out.addAll(gr.games);
        }
      }
    }
    return out;
  }

  /// Öne çıkanlar: stildeki liste, sonra bölüm sırası (en çok 12).
  List<GameConfig> _featuredGames(int? section) {
    if (section != null && section >= 0) return _sectionGames(section);
    final out = <GameConfig>[];
    final seen = <String>{};
    void add(GameConfig? g) {
      if (g != null && seen.add(g.gameId)) out.add(g);
    }

    for (final id in style.featured) {
      add(_game(id));
    }
    for (var i = 0; i < hub.sections.length && out.length < 12; i++) {
      for (final g in _sectionGames(i)) {
        add(g);
      }
    }
    for (final g in hub.allGames) {
      if (out.length >= 12) break;
      add(g);
    }
    return out.take(12).toList();
  }

  DateTime get _weekStart {
    final n = DateTime.now();
    final d = DateTime(n.year, n.month, n.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String get _weekKey => _day(_weekStart);

  int get _playedThisWeek {
    final start = _day(_weekStart);
    return _sums.values.where((s) => s.day.compareTo(start) >= 0).length;
  }

  int get _totalCompleted => _sums.values.fold(0, (a, s) => a + s.completed);

  // ---- Görünüm ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      1 => _gamesTab(),
      2 => _anchorTab((s) => const DailyScreen()),
      3 => _anchorTab((s) => const ProfileScreen()),
      _ => _homeTab(),
    };
    return Scaffold(
      key: _scaffold,
      backgroundColor: style.background.last,
      drawer: _drawer(),
      body: _Backdrop(style: style, child: SafeArea(bottom: false, child: body)),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar({String? title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () => _scaffold.currentState?.openDrawer(),
        ),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(hub.icon, color: style.accent, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title ?? hub.localized(hub.title, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        IconButton(
          tooltip: Strings(lang).t('shop'),
          icon: const SizedBox(width: 30, height: 26, child: CustomPaint(painter: _CrownPainter())),
          onPressed: _openShop,
        ),
      ]),
    );
  }

  Widget _homeTab() {
    final children = <Widget>[_topBar(), _hero()];
    final searching = _query.trim().isNotEmpty;
    for (final b in style.blocks) {
      if (searching && b != ApprovedBlock.search) continue;
      final w = _block(b);
      if (w != null) children.add(w);
    }
    if (searching) children.add(_searchResults());
    children.add(const SizedBox(height: 24));
    return ListView(padding: EdgeInsets.zero, children: children);
  }

  Widget? _block(ApprovedBlock b) {
    switch (b) {
      case ApprovedBlock.search:
        return _search();
      case ApprovedBlock.chips:
        return hub.sections.isEmpty ? null : _chips();
      case ApprovedBlock.featured:
        return _featured();
      case ApprovedBlock.categories:
        return hub.sections.isEmpty ? null : _categories();
      case ApprovedBlock.weeklyQuest:
        return _weeklyQuest();
      case ApprovedBlock.progress:
        return _progress();
      case ApprovedBlock.dailyReward:
        return _dailyReward();
      case ApprovedBlock.dailyChallenge:
        return _game(style.challengeGameId ?? '') == null ? null : _dailyChallenge();
      case ApprovedBlock.brainStats:
        return hub.sections.isEmpty ? null : _brainStats();
      case ApprovedBlock.weeklyContest:
        return _weeklyContest();
      case ApprovedBlock.categoryTiles:
        return style.categoryTiles.isEmpty ? null : _categoryTiles();
      case ApprovedBlock.scoreRank:
        return _scoreRank();
      case ApprovedBlock.playNow:
        return _playNow();
      case ApprovedBlock.campaign:
        return hub.sections.isEmpty ? null : _campaign();
      case ApprovedBlock.currency:
        return _currency();
      case ApprovedBlock.growth:
        return _growth();
    }
  }

  Widget _hero() {
    final n = hub.allGames.length;
    return Container(
      height: style.heroTitle ? 220 : 200,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(children: [
        if (style.heroAsset != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: Image.asset(style.heroAsset!,
                  fit: BoxFit.contain, alignment: Alignment.centerRight, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.sizeOf(context).width * 0.56,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(tx('n_games', {'n': n}),
                  style: TextStyle(
                      color: style.number,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))])),
            ),
            if (style.heroTitle)
              Text(hub.localized(hub.title, lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))])),
            const SizedBox(height: 6),
            Text(hub.localized(hub.tagline, lang),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.25,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
          ]),
        ),
      ]),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          hintText: tx('search'),
          hintStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
        ),
      ),
    );
  }

  Widget _searchResults() {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final g in hub.allGames)
        if (hub.localized(g.title, lang).toLowerCase().contains(q)) g
    ];
    return _grid(list);
  }

  Widget _grid(List<GameConfig> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, c) {
        final cols = math.max(3, (c.maxWidth / 130).floor());
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final g in list) SizedBox(width: w, height: w * 1.45, child: _tile(g)),
        ]);
      }),
    );
  }

  Widget _chips() {
    final labels = [tx('all'), for (final s in hub.sections) hub.localized(s.title, lang)];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final sel = _chip == i - 1;
          return _Pill(
            label: labels[i],
            selected: sel,
            accent: style.accent,
            onTap: () => setState(() {
              _chip = i - 1;
              _page = 0;
              if (_pager.hasClients) _pager.jumpToPage(0);
            }),
          );
        },
      ),
    );
  }

  Widget _header(IconData icon, Color iconColor, String title, {VoidCallback? onAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (onAll != null)
          InkWell(
            onTap: onAll,
            child: Text('${tx('all')} ›',
                style: TextStyle(color: style.accent, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  Widget _featured() {
    final games = _featuredGames(_chip >= 0 ? _chip : null);
    if (games.isEmpty) return const SizedBox.shrink();
    final per = style.tilesPerPage;
    final pages = (games.length / per).ceil();
    final isPopular = style.featuredKey == 'popular';
    return Column(children: [
      _header(isPopular ? Icons.local_fire_department_rounded : Icons.star_rounded,
          isPopular ? const Color(0xFFFF8A1F) : const Color(0xFFFFC93C), tx(style.featuredKey),
          onAll: () => setState(() => _tab = 1)),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 32 - (per - 1) * 10) / per;
        return SizedBox(
          height: w * 1.45,
          child: PageView.builder(
            controller: _pager,
            itemCount: pages,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (c, p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                for (var i = 0; i < per; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  SizedBox(
                    width: w,
                    child: p * per + i < games.length ? _tile(games[p * per + i]) : const SizedBox(),
                  ),
                ],
              ]),
            ),
          ),
        );
      }),
      if (pages > 1)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? style.accent : Colors.white.withValues(alpha: 0.35)),
              ),
          ]),
        ),
    ]);
  }

  Widget _art(GameConfig g, double size) {
    final asset = style.tileArt[g.gameId];
    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.16),
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverOrIcon(g, size)),
      );
    }
    return _coverOrIcon(g, size);
  }

  Widget _coverOrIcon(GameConfig g, double size) {
    final cover = hub.coverFor(g.gameId);
    if (cover != null) return CoverArt(cover: cover, color: g.seedColor, size: size, radius: size * 0.16);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.16),
        gradient: LinearGradient(colors: [g.seedColor, Color.lerp(g.seedColor, Colors.black, 0.35)!]),
      ),
      child: Icon(g.icon, color: Colors.white, size: size * 0.55),
    );
  }

  Widget _tile(GameConfig g) {
    final busy = _opening == g.gameId;
    final title = hub.localized(g.title, lang);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(g),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(style.card, Colors.white, 0.10)!, Color.lerp(style.card, Colors.black, 0.35)!],
              ),
              border: Border.all(color: style.accent.withValues(alpha: 0.55), width: 1.4),
              boxShadow: [BoxShadow(color: style.accent.withValues(alpha: 0.25), blurRadius: 10)],
            ),
            child: LayoutBuilder(builder: (context, c) {
              final art = c.maxWidth - 12;
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    _art(g, art),
                    if (busy) const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ]),
                  Expanded(
                    child: Center(
                      child: Text(title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Container(
                    width: art * 0.6,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [style.play, Color.lerp(style.play, Colors.white, 0.25)!]),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap, Gradient? gradient}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: gradient == null ? Colors.white.withValues(alpha: 0.07) : null,
              gradient: gradient,
              border: Border.all(color: style.accent.withValues(alpha: 0.45)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _bar(double v, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
          value: v.clamp(0.0, 1.0).toDouble(),
          minHeight: 9,
          color: color,
          backgroundColor: Colors.white.withValues(alpha: 0.15)),
    );
  }

  Widget _titleBody(String title, String body) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  Widget _categories() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header(Icons.layers_rounded, Colors.white, hub.localized(style.categoriesLabel ?? _kTx['categories']!, lang)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in hub.sections)
            _Pill(
              label: hub.localized(s.title, lang),
              selected: false,
              accent: style.accent,
              onTap: () => _openSection(s.title, s.ids),
            ),
        ]),
      ),
    ]);
  }

  Widget _weeklyQuest() {
    final target = style.questTarget;
    final n = math.min(_playedThisWeek, target);
    final done = n >= target;
    final claimed = _questWeek == _weekKey;
    return _card(
      onTap: () async {
        if (done && !claimed) {
          await _grant(100);
          _questWeek = _weekKey;
          await widget.services.backend.write('hub.quest', _questWeek);
          if (mounted) setState(() {});
          return;
        }
        final start = _day(_weekStart);
        final fresh = [
          for (final g in hub.allGames)
            if ((_sums[g.gameId]?.day ?? '').compareTo(start) < 0) g
        ];
        if (fresh.isNotEmpty) await _open(fresh[DateTime.now().millisecond % fresh.length]);
      },
      child: Row(children: [
        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC93C), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _titleBody(tx('quest_title'), done && !claimed ? tx('claim') : tx('quest_body', {'n': target})),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _bar(n / target, style.accent)),
              const SizedBox(width: 8),
              Text(claimed ? '✓' : '$n/$target', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
      ]),
    );
  }

  Widget _progress() {
    final total = math.max(1, hub.allGames.length);
    final tried = hub.allGames.where((g) => _sums.containsKey(g.gameId)).length;
    final pct = (100 * tried / total).round();
    return _card(
      onTap: () => setState(() => _tab = 1),
      child: Row(children: [
        Icon(Icons.bar_chart_rounded, color: style.accent, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _titleBody(tx('progress_title'), tx('progress_body')),
            const SizedBox(height: 8),
            _bar(tried / total, style.accent),
          ]),
        ),
        const SizedBox(width: 12),
        Text('%$pct', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Future<void> _grant(int coins) async {
    final a = _anchor;
    if (a == null) return;
    a.save.coins += coins;
    a.changed(saveNow: true);
  }

  Widget _dailyReward() {
    final today = _day(DateTime.now());
    final claimed = _giftDay == today;
    return _card(
      onTap: claimed || _anchor == null
          ? null
          : () async {
              await _grant(50);
              _giftDay = today;
              await widget.services.backend.write('hub.gift', today);
              if (mounted) setState(() {});
            },
      child: Row(children: [
        Icon(claimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
            color: const Color(0xFFFF5FB4), size: 44),
        const SizedBox(width: 12),
        Expanded(child: _titleBody(tx('gift_title'), claimed ? tx('gift_done') : tx('gift_body'))),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
      ]),
    );
  }

  Widget _dailyChallenge() {
    final g = _game(style.challengeGameId!)!;
    return _card(
      onTap: () => _open(g),
      child: Row(children: [
        Icon(Icons.event_available_rounded, color: style.accent, size: 40),
        const SizedBox(width: 12),
        Expanded(child: _titleBody(tx('challenge_title'), tx('challenge_body'))),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
      ]),
    );
  }

  /// Bir bölümdeki oyunların yıldız başarısı (0–1).
  double _sectionScore(int i) {
    var got = 0, max = 0;
    for (final g in _sectionGames(i)) {
      final s = _sums[g.gameId];
      if (s == null || s.completed == 0) continue;
      got += s.stars;
      max += s.completed * 3;
    }
    return max == 0 ? 0 : got / max;
  }

  Widget _brainStats() {
    const colors = [Color(0xFF2FD3F5), Color(0xFFB06CFF), Color(0xFFFF9F2E), Color(0xFF3BE37A)];
    final idx = [
      for (var i = 0; i < hub.sections.length; i++)
        if (_sectionGames(i).length > 1 || hub.sections.length <= 4) i
    ].take(4).toList();
    return _card(
      child: Column(children: [
        Row(children: [
          Icon(hub.icon, color: style.accent, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tx('stats_title'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var k = 0; k < idx.length; k++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(children: [
                  Text(hub.localized(hub.sections[idx[k]].title, lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('%${(100 * _sectionScore(idx[k])).round()}',
                      style: TextStyle(color: colors[k % colors.length], fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  _bar(_sectionScore(idx[k]), colors[k % colors.length]),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }

  GameConfig? get _weekGame {
    final list = _featuredGames(null);
    if (list.isEmpty) return null;
    return list[weekIndex(DateTime.now()) % list.length];
  }

  Widget _weeklyContest() {
    final g = _weekGame;
    return _card(
      onTap: g == null ? null : () => _open(g),
      gradient: const LinearGradient(colors: [Color(0xFFE2541F), Color(0xFF9E2A8C)]),
      child: Row(children: [
        const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFC93C), size: 40),
        const SizedBox(width: 12),
        Expanded(child: _titleBody(tx('contest_title'), tx('contest_body'))),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
      ]),
    );
  }

  Widget _categoryTiles() {
    return Column(children: [
      _header(Icons.menu_book_rounded, Colors.white, hub.localized(style.categoriesLabel ?? _kTx['categories']!, lang),
          onAll: () => setState(() => _tab = 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (var i = 0; i < style.categoryTiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _categoryTile(style.categoryTiles[i])),
          ],
        ]),
      ),
    ]);
  }

  Widget _categoryTile(ApprovedCategory c) {
    final title = hub.localized(c.title, lang);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSection(c.title, c.ids),
        child: AspectRatio(
          aspectRatio: 0.92,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(c.color, Colors.white, 0.15)!, c.color]),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: c.asset != null
                      ? Image.asset(c.asset!,
                          fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(c.icon, color: Colors.white, size: 34))
                      : Icon(c.icon, color: Colors.white, size: 34),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _scoreRank() {
    final points = _sums.values.fold(0, (a, s) => a + s.xp);
    return _card(
      onTap: _openLeaderboard,
      child: Row(children: [
        const Icon(Icons.military_tech_rounded, color: Color(0xFFFFC93C), size: 36),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx('points'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(_compact(points), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
        ),
        Container(width: 1, height: 40, color: Colors.white24),
        const SizedBox(width: 12),
        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC93C), size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx('rank'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(Strings(lang).t('leaderboards'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
      ]),
    );
  }

  Future<void> _openLeaderboard() async {
    final a = _anchor;
    if (a == null || !Online.instance.available) return;
    if (!await Online.instance.start()) return;
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LeaderboardScreen(app: a)));
  }

  Widget _playNow() {
    final feat = _featuredGames(null);
    final g = _anchor == null ? (feat.isNotEmpty ? feat.first : null) : _game(_anchor!.config.gameId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: g == null ? null : () => _open(g),
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFFFFB21F), Color(0xFFFF7A1A)]),
              boxShadow: const [BoxShadow(color: Color(0x66FF8A1F), blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
              const SizedBox(width: 8),
              Text(tx('play_now'),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _campaign() {
    final m = hub.sections.length;
    var n = 0;
    for (var i = 0; i < m; i++) {
      if (_sectionGames(i).any((g) => (_sums[g.gameId]?.completed ?? 0) > 0)) n++;
    }
    return _card(
      onTap: () => setState(() => _tab = 1),
      child: Row(children: [
        const Icon(Icons.shield_rounded, color: Color(0xFFFF5A5A), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(tx('campaign'),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text(tx('n_of_m', {'n': n, 'm': m}),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            _bar(m == 0 ? 0 : n / m, style.accent),
          ]),
        ),
      ]),
    );
  }

  Widget _currency() {
    final s = _anchor?.save;
    Widget pill(IconData icon, Color color, String value, bool plus) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: plus ? _openShop : null,
          child: Ink(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withValues(alpha: 0.30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 6),
              Expanded(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              if (plus) const Icon(Icons.add_circle_rounded, color: Color(0xFF3BD45A), size: 24),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(children: [
        pill(Icons.monetization_on_rounded, const Color(0xFFFFC93C), _compact(s?.coins ?? 0), true),
        const SizedBox(width: 8),
        pill(Icons.diamond_rounded, const Color(0xFFD36BFF), _compact(s?.gems ?? 0), true),
        const SizedBox(width: 8),
        pill(Icons.bolt_rounded, const Color(0xFFFFD23F), '${s?.lives ?? 0}', false),
      ]),
    );
  }

  Widget _growth() {
    const per = 25;
    final total = _totalCompleted;
    final level = 1 + total ~/ per;
    final frac = (total % per) / per;
    return _card(
      child: Row(children: [
        Icon(hub.icon, color: const Color(0xFFFFC93C), size: 36),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFFFE08A), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(tx('level'), style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w700)),
            Text('$level', style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hub.localized(style.growthLabel ?? _kTx['growth']!, lang),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _bar(frac, const Color(0xFF3BD45A)),
          ]),
        ),
        const SizedBox(width: 10),
        Text('%${(frac * 100).round()}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  // ---- Sekmeler --------------------------------------------------------------

  Widget _gamesTab() {
    final children = <Widget>[_topBar(title: tx('nav_games'))];
    final used = <String>{};
    for (var i = 0; i < hub.sections.length; i++) {
      final list = _sectionGames(i);
      if (list.isEmpty) continue;
      used.addAll(list.map((g) => g.gameId));
      children.add(_header(Icons.grid_view_rounded, style.accent, '${hub.localized(hub.sections[i].title, lang)} · ${list.length}'));
      children.add(_grid(list));
    }
    final rest = [for (final g in hub.allGames) if (!used.contains(g.gameId)) g];
    if (rest.isNotEmpty) {
      if (hub.sections.isNotEmpty) children.add(_header(Icons.grid_view_rounded, style.accent, tx('all')));
      children.add(_grid(rest));
    }
    children.add(const SizedBox(height: 24));
    return ListView(padding: EdgeInsets.zero, children: children);
  }

  Widget _anchorTab(Widget Function(AppState) page) {
    final a = _anchor;
    final title = _tab == 2 ? tx('nav_tasks') : tx('nav_profile');
    if (a == null) {
      return Column(children: [_topBar(title: title), const Expanded(child: Center(child: CircularProgressIndicator()))]);
    }
    final g = _game(a.config.gameId);
    return Column(children: [
      _topBar(title: title),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(children: [
          if (g != null) _art(g, 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(g == null ? a.config.gameId : hub.localized(g.title, lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            onPressed: _pickAnchor,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(tx('change_game')),
          ),
        ]),
      ),
      Expanded(
        child: ProviderScope(
          key: ValueKey('${_tab}_${a.config.gameId}'),
          overrides: [appStateProvider.overrideWith((ref) => a)],
          child: page(a),
        ),
      ),
    ]);
  }

  Future<void> _pickAnchor() async {
    final played = [for (final g in hub.allGames) if (_sums.containsKey(g.gameId)) g];
    final list = played.isEmpty ? hub.allGames : played;
    final chosen = await showModalBottomSheet<GameConfig>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final g in list)
            ListTile(
              leading: _art(g, 40),
              title: Text(hub.localized(g.title, lang)),
              onTap: () => Navigator.pop(c, g),
            ),
        ]),
      ),
    );
    if (chosen == null) return;
    final st = await widget.services.stateFor(chosen);
    if (mounted) setState(() => _anchor = st);
  }

  Future<void> _openShop() async {
    final a = _anchor;
    if (a == null) return;
    widget.services.active = a;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProviderScope(overrides: [appStateProvider.overrideWith((ref) => a)], child: const ShopScreen()),
      ),
    );
    widget.services.active = null;
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    final a = _anchor;
    if (a == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ProviderScope(overrides: [appStateProvider.overrideWith((ref) => a)], child: const SettingsScreen()),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _drawer() {
    final s = Strings(lang);
    final sisters = (kIsWeb || defaultTargetPlatform == TargetPlatform.android)
        ? [for (final a in studioApps) if (a.hubId != hub.hubId) a]
        : const <StudioApp>[];
    return Drawer(
      backgroundColor: style.background.last,
      child: SafeArea(
        child: ListView(children: [
          ListTile(
            leading: Icon(hub.icon, color: style.accent, size: 32),
            title: Text(hub.localized(hub.title, lang),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: Text(s.t('shop')),
            onTap: () {
              Navigator.pop(context);
              unawaited(_openShop());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(s.t('settings')),
            onTap: () {
              Navigator.pop(context);
              unawaited(_openSettings());
            },
          ),
          if (Online.instance.available)
            ListTile(
              leading: const Icon(Icons.leaderboard_rounded),
              title: Text(s.t('leaderboards')),
              onTap: () {
                Navigator.pop(context);
                unawaited(_openLeaderboard());
              },
            ),
          if (sisters.isNotEmpty) ...[
            const Divider(),
            ListTile(title: Text(tx('more_apps'), style: const TextStyle(fontWeight: FontWeight.w800))),
            for (final a in sisters)
              ListTile(
                leading: Icon(a.icon, color: a.color),
                title: Text(hub.localized(a.title, lang)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () async {
                  // Çocuk uygulamasında dış bağlantı ebeveyn kapısının arkasında.
                  final st = _anchor;
                  if (st != null && !await parentalGate(context, st)) return;
                  await launchUrl(a.playUrl, mode: LaunchMode.externalApplication);
                },
              ),
          ],
        ]),
      ),
    );
  }

  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, tx('nav_home')),
      (Icons.sports_esports_rounded, tx('nav_games')),
      (Icons.emoji_events_outlined, tx('nav_tasks')),
      (Icons.person_outline_rounded, tx('nav_profile')),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Color.lerp(style.background.last, Colors.black, 0.25),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
      ),
      child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: _tab == i,
              label: items[i].$2,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: _tab == i
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [style.accent.withValues(alpha: 0.85), style.accent.withValues(alpha: 0.45)]),
                        )
                      : null,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].$1, color: Colors.white, size: 26),
                    const SizedBox(height: 2),
                    Text(items[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: _tab == i ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Bir bölümün ya da kategorinin oyun listesi.
class _GameListPage extends StatelessWidget {
  final String title;
  final ApprovedHubStyle style;
  final List<GameConfig> games;
  final Widget Function(GameConfig) tile;
  const _GameListPage({required this.title, required this.style, required this.games, required this.tile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: style.background.last,
      appBar: AppBar(
        backgroundColor: style.background.first,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: _Backdrop(
        style: style,
        child: LayoutBuilder(builder: (context, c) {
          final cols = math.max(3, (c.maxWidth / 130).floor());
          final w = (c.maxWidth - 32 - (cols - 1) * 10) / cols;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final g in games) SizedBox(width: w, height: w * 1.45, child: tile(g)),
            ]),
          ]);
        }),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? accent : Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: selected ? accent : Colors.white.withValues(alpha: 0.35)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Altın taç (mağaza düğmesi).
class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.85)
      ..lineTo(w * 0.02, h * 0.25)
      ..lineTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.98, h * 0.25)
      ..lineTo(w * 0.92, h * 0.85)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE27A), Color(0xFFF2A21C)])
          .createShader(Offset.zero & s);
    canvas.drawPath(path, paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.80, w * 0.84, h * 0.16), const Radius.circular(2)),
        Paint()..color = const Color(0xFFE08A10));
    final dot = Paint()..color = const Color(0xFFFFF4C2);
    for (final x in [0.02, 0.50, 0.98]) {
      canvas.drawCircle(Offset(w * x, h * (x == 0.50 ? 0.10 : 0.25)), w * 0.07, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
