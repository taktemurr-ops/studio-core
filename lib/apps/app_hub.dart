/// Uygulama merkezlerinin (Araç Kutusu, Verimlilik, …) ortak kabuğu.
///
/// Oyun merkezlerinin onaylı görünümünü ([ApprovedHubStyle]) aynen taşır:
/// koyu degrade zemin, italik "N Uygulama" kahraman yazısı, yuvarlak arama
/// kutusu, vurgu çerçeveli kutular. Alt gezinme: Ana Sayfa · Uygulamalar ·
/// Favoriler · Profil. Reklam ve satın alma oyunlardaki hizmetlerle yapılır;
/// geçiş reklamı yalnızca bir araçtan çıkarken (doğal ara) ve en az 3
/// dakika arayla gösterilir, bir iş sürerken asla gösterilmez.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/approved_hub.dart' show ApprovedHubStyle, ApprovedLook;
import '../app/studio_ui.dart';
import '../app/desktop_input.dart';
import '../app/edition.dart';
import '../app/services/ads.dart';
import '../app/services/prefs_backend.dart';
import '../app/services/purchases.dart';
import '../core/monetization.dart';
import '../core/strings.dart';
import 'app_config.dart';
import 'app_services.dart';
import 'app_tx.dart';
import 'app_widgets.dart';

/// Uygulama merkezinin `main()` girişi.
void bootstrapAppHub(AppHubConfig hubConfig) {
  final config = hubConfig.forPlatform(desktop: Edition.desktop);
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final backend = await PrefsBackend.create();
    final services = AppServices(
      hubId: config.hubId,
      backend: backend,
      ads: AdsService.create(),
      purchases: PurchaseService.create(),
    );
    await services.load();
    if (Edition.desktop) {
      // Masaüstü sürümü mağazada ücretli tam sürüm: reklamsız ve premium açık.
      services.entitlements.addAll(Edition.desktopEntitlements);
      if (services.consent == null) await services.setConsent(false);
    }
    if (services.consent != null) unawaited(services.startServices());
    runApp(AppHubApp(config: config, services: services));
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}

class AppHubApp extends StatefulWidget {
  final AppHubConfig config;
  final AppServices services;
  const AppHubApp({super.key, required this.config, required this.services});

  @override
  State<AppHubApp> createState() => _AppHubAppState();
}

class _AppHubAppState extends State<AppHubApp> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return ValueListenableBuilder<int>(
      valueListenable: s.changes,
      builder: (context, _, __) {
        final lang = s.language ?? Strings.pickLanguage(PlatformDispatcher.instance.locale.languageCode);
        final style = widget.config.style;
        final look = style.look;
        final theme = buildStudioTheme(look);
        return StudioLookScope(
          look: look,
          child: MaterialApp(
            title: widget.config.localized(widget.config.title, lang),
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
            navigatorKey: _navKey,
            scrollBehavior: const StudioScrollBehavior(),
            builder: (context, child) => DesktopInput(
              navigatorKey: _navKey,
              child: AppLook(style: style, child: child ?? const SizedBox()),
            ),
            home: s.consent == null
                ? AppConsentPage(
                    config: widget.config,
                    lang: lang,
                    onChoice: (all) async {
                      await s.setConsent(all);
                      if (mounted) setState(() {});
                    },
                  )
                : AppHubShell(config: widget.config, services: s, lang: lang),
          ),
        );
      },
    );
  }
}

/// İlk açılışta gizlilik tercihi (reklam kişiselleştirme).
class AppConsentPage extends StatelessWidget {
  final AppHubConfig config;
  final String lang;
  final Future<void> Function(bool acceptAll) onChoice;
  const AppConsentPage({super.key, required this.config, required this.lang, required this.onChoice});

  @override
  Widget build(BuildContext context) {
    final t = Strings(lang);
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
                Icon(config.icon, size: 64, color: AppLook.of(context).accent),
                const SizedBox(height: 12),
                Text(config.localized(config.title, lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                AppPanel(
                  margin: EdgeInsets.zero,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.t('consent_title'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(t.t('consent_body'), style: const TextStyle(color: Colors.white70, height: 1.35)),
                  ]),
                ),
                const SizedBox(height: 16),
                AppButton(label: t.t('accept_all'), icon: Icons.check_rounded, onPressed: () => onChoice(true)),
                TextButton(
                  onPressed: () => onChoice(false),
                  child: Text(t.t('essential_only'), style: const TextStyle(color: Colors.white70)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ana kabuk: dört sekme.
class AppHubShell extends StatefulWidget {
  final AppHubConfig config;
  final AppServices services;
  final String lang;
  const AppHubShell({super.key, required this.config, required this.services, required this.lang});

  @override
  State<AppHubShell> createState() => _AppHubShellState();
}

class _AppHubShellState extends State<AppHubShell> {
  int _tab = 0;
  String _query = '';
  String? _category;
  StreamSubscription<AppNotice>? _sub;

  AppHubConfig get config => widget.config;
  AppServices get services => widget.services;
  String get lang => widget.lang;
  String tx(String key, [Map<String, Object> p = const {}]) => appTx(key, lang, p);
  String core(String key) => Strings(lang).t(key);

  @override
  void initState() {
    super.initState();
    _sub = services.notices.stream.listen((n) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(core(n.key))));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _open(AppTool tool) async {
    await services.touchRecent(tool.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AppToolPage(config: config, tool: tool, services: services, lang: lang),
    ));
    // Araçtan çıkış doğal bir aradır; kurallar uygunsa geçiş reklamı.
    await services.naturalBreak();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _all(), _favorites(), _profile()];
    return Scaffold(
      backgroundColor: AppLook.of(context).background.last,
      body: AppBackdrop(child: SafeArea(bottom: false, child: pages[_tab])),
      bottomNavigationBar: StudioNavBar(
        selected: _tab,
        onTap: (i) => setState(() {
          _tab = i;
          _query = '';
        }),
        items: [
          StudioNavItem(Icons.home_rounded, tx('nav_home')),
          StudioNavItem(Icons.apps_rounded, tx('nav_apps')),
          StudioNavItem(Icons.star_rounded, tx('nav_favorites')),
          StudioNavItem(Icons.person_rounded, tx('nav_profile')),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- sekmeler

  Widget _home() {
    final q = _query.trim();
    final featured = [
      for (final id in config.featured)
        if (config.tool(id) != null) config.tool(id)!,
    ];
    if (featured.isEmpty) featured.addAll(config.tools.take(6));
    final recents = [
      for (final id in services.recents)
        if (config.tool(id) != null) config.tool(id)!,
    ];
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      _hero(),
      _search(),
      if (q.isNotEmpty)
        _grid(_matches(q), emptyText: tx('no_results'))
      else ...[
        AppHeading(tx('featured'), icon: Icons.auto_awesome_rounded),
        _strip(featured),
        if (recents.isNotEmpty) ...[
          AppHeading(tx('recent'), icon: Icons.history_rounded),
          _strip(recents),
        ],
        AppHeading(tx('categories'), icon: Icons.category_rounded),
        _categoryChips(),
        _grid(_inCategory()),
      ],
    ]);
  }

  Widget _all() {
    final q = _query.trim();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      AppHeading(tx('n_apps', {'n': config.tools.length}), icon: Icons.apps_rounded),
      _search(),
      if (q.isEmpty) _categoryChips(),
      _grid(q.isEmpty ? _inCategory() : _matches(q), emptyText: tx('no_results')),
    ]);
  }

  Widget _favorites() {
    final favs = [
      for (final id in services.favorites)
        if (config.tool(id) != null) config.tool(id)!,
    ];
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      AppHeading(tx('nav_favorites'), icon: Icons.star_rounded),
      if (favs.isEmpty) AppInfoCard(tx('no_favorites'), icon: Icons.star_border_rounded) else _grid(favs),
    ]);
  }

  Widget _profile() {
    final t = Strings(lang);
    final owned = services.entitlements;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      AppHeading(tx('nav_profile'), icon: Icons.person_rounded),
      AppPanel(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(t.t('language')),
            subtitle: Text(lang),
            onTap: _pickLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: Text(t.t('ad_settings')),
            onTap: () async {
              await services.ads.openPrivacyOptions();
              if (!mounted) return;
              await showDialog<void>(
                context: context,
                builder: (c) => SimpleDialog(title: Text(t.t('consent_title')), children: [
                  SimpleDialogOption(
                    onPressed: () {
                      services.setConsent(true);
                      Navigator.pop(c);
                    },
                    child: Text(t.t('accept_all')),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      services.setConsent(false);
                      Navigator.pop(c);
                    },
                    child: Text(t.t('essential_only')),
                  ),
                ]),
              );
            },
          ),
          if (config.privacyUrl != null)
            ListTile(
              leading: const Icon(Icons.policy_rounded),
              title: Text(t.t('privacy_policy')),
              onTap: () => launchUrl(Uri.parse(config.privacyUrl!), mode: LaunchMode.externalApplication),
            ),
        ]),
      ),
      AppHeading(t.t('shop'), icon: Icons.storefront_rounded),
      AppPanel(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          _product(Products.removeAds, t.t('remove_ads'), t.t('remove_ads_desc'), owned.contains(Products.removeAds)),
          _product(Products.premium, t.t('premium_pack'), t.t('premium_desc'), owned.contains(Products.premium)),
          ListTile(
            leading: const Icon(Icons.restore_rounded),
            title: Text(t.t('restore_purchases')),
            onTap: services.purchases.available ? services.restore : null,
          ),
          if (!services.purchases.available)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(t.t('store_unavailable'), style: const TextStyle(color: Colors.white60)),
            ),
        ]),
      ),
      AppPanel(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded),
            title: Text(t.t('delete_data')),
            onTap: _confirmDelete,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(t.t('about')),
            subtitle: Text(config.localized(config.tagline, lang)),
          ),
        ]),
      ),
    ]);
  }

  Widget _product(String id, String title, String desc, bool isOwned) {
    return ListTile(
      leading: Icon(id == Products.premium ? Icons.workspace_premium_rounded : Icons.block_rounded),
      title: Text(title),
      subtitle: Text(desc),
      trailing: isOwned
          ? Text(core('owned'), style: TextStyle(color: AppLook.of(context).accent))
          : const Icon(Icons.chevron_right_rounded),
      onTap: isOwned || !services.purchases.available ? null : () => services.buy(id),
    );
  }

  Future<void> _pickLanguage() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(core('language')),
        children: [
          for (final l in Strings.languages)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, l),
              child: Text(l, style: TextStyle(fontWeight: l == lang ? FontWeight.w900 : FontWeight.w400)),
            ),
        ],
      ),
    );
    if (picked != null) await services.setLanguage(picked);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        icon: const Icon(Icons.delete_forever_rounded, color: StudioLook.bad, size: 40),
        title: Text(core('delete_data')),
        content: Text(core('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(core('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(core('delete'))),
        ],
      ),
    );
    if (ok == true) await services.deleteAll(config.tools.map((t) => t.id));
  }

  // ------------------------------------------------------------ yapı taşları

  Widget _hero() {
    final s = AppLook.of(context);
    // Büyük yazıda başlık ve açıklama kesilmesin: alan yazı boyutuyla büyür.
    final ts = MediaQuery.textScalerOf(context);
    final need = ts.scale(48) + ts.scale(24 * 1.05 * 2) + 6 + ts.scale(14 * 1.25 * 3) + 12;
    return Container(
      height: math.max(190.0, need),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(children: [
        if (s.heroAsset != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: Image.asset(s.heroAsset!,
                  fit: BoxFit.contain, alignment: Alignment.centerRight, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          )
        else
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: ExcludeSemantics(child: Icon(config.icon, size: 120, color: s.accent.withValues(alpha: 0.35))),
          ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.sizeOf(context).width * 0.6,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(tx('n_apps', {'n': config.tools.length}),
                  style: TextStyle(
                      color: s.number,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))])),
            ),
            Text(config.localized(config.title, lang),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))])),
            const SizedBox(height: 6),
            Text(config.localized(config.tagline, lang),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.25, shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
          ]),
        ),
      ]),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        key: const ValueKey('app-search'),
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

  List<AppTool> _matches(String q) {
    final needle = q.toLowerCase();
    return [
      for (final t in config.tools)
        if (config.localized(t.title, lang).toLowerCase().contains(needle) ||
            config.localized(t.tagline, lang).toLowerCase().contains(needle) ||
            t.keywords.any((k) => k.toLowerCase().contains(needle)) ||
            t.title.any((k) => k.toLowerCase().contains(needle)))
          t,
    ];
  }

  List<AppTool> _inCategory() =>
      _category == null ? config.tools : [for (final t in config.tools) if (t.category == _category) t];

  Widget _categoryChips() {
    final s = AppLook.of(context);
    Widget chip(String? id, String label, IconData icon) {
      final sel = _category == id;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          avatar: Icon(icon, size: 18, color: sel ? Colors.black87 : Colors.white70),
          label: Text(label),
          selected: sel,
          selectedColor: s.accent,
          labelStyle: TextStyle(color: sel ? Colors.black87 : Colors.white, fontWeight: FontWeight.w700),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          onSelected: (_) => setState(() => _category = id),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        chip(null, tx('all'), Icons.apps_rounded),
        for (final c in config.categories) chip(c.id, config.localized(c.title, lang), c.icon),
      ]),
    );
  }

  Widget _strip(List<AppTool> tools) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 118, child: _tile(tools[i])),
      ),
    );
  }

  Widget _grid(List<AppTool> tools, {String? emptyText}) {
    if (tools.isEmpty) return emptyText == null ? const SizedBox() : AppInfoCard(emptyText);
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 150).floor().clamp(2, 8);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.86),
        itemCount: tools.length,
        itemBuilder: (_, i) => _tile(tools[i]),
      );
    });
  }

  Widget _tile(AppTool tool) {
    final s = AppLook.of(context);
    final title = config.localized(tool.title, lang);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('tool-${tool.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(tool),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(s.card, Colors.white, 0.10)!, Color.lerp(s.card, Colors.black, 0.35)!],
              ),
              border: Border.all(color: s.accent.withValues(alpha: 0.55), width: 1.4),
              boxShadow: [BoxShadow(color: s.accent.withValues(alpha: 0.25), blurRadius: 10)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [tool.color, Color.lerp(tool.color, Colors.black, 0.35)!]),
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 8),
                Text(title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek bir aracın ekranı: başlık, favori yıldızı, gerekiyorsa uyarı bandı.
class AppToolPage extends StatefulWidget {
  final AppHubConfig config;
  final AppTool tool;
  final AppServices services;
  final String lang;
  const AppToolPage({super.key, required this.config, required this.tool, required this.services, required this.lang});

  @override
  State<AppToolPage> createState() => _AppToolPageState();
}

class _AppToolPageState extends State<AppToolPage> {
  late final ToolContext _ctx = ToolContext(
    toolId: widget.tool.id,
    lang: widget.lang,
    store: widget.services.storeFor(widget.tool.id),
    services: widget.services,
  );

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final fav = widget.services.isFavorite(tool.id);
    final s = AppLook.of(context);
    return Scaffold(
      backgroundColor: s.background.last,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: StudioTitle(
          widget.config.localized(tool.title, widget.lang),
          art: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [tool.color, Color.lerp(tool.color, Colors.black, 0.35)!]),
            ),
            child: Icon(tool.icon, color: Colors.white, size: 18),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('fav-toggle'),
            tooltip: appTx(fav ? 'remove_fav' : 'add_fav', widget.lang),
            icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? s.accent : null),
            onPressed: () async {
              await widget.services.toggleFavorite(tool.id);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: Column(children: [
            if (tool.disclaimer != AppDisclaimer.none) AppDisclaimerBanner(kind: tool.disclaimer, lang: widget.lang),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Builder(builder: (c) => tool.builder(c, _ctx)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Sağlık ve finans araçlarında her zaman görünen bilgilendirme.
class AppDisclaimerBanner extends StatelessWidget {
  final AppDisclaimer kind;
  final String lang;
  const AppDisclaimerBanner({super.key, required this.kind, required this.lang});

  @override
  Widget build(BuildContext context) {
    final text = appTx(kind == AppDisclaimer.wellness ? 'wellness' : 'finance', lang);
    return Container(
      width: double.infinity,
      color: Colors.amber.withValues(alpha: 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        const Icon(Icons.info_rounded, color: Colors.amberAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
      ]),
    );
  }
}
