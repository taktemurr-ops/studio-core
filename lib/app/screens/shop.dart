import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/monetization.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../parental_gate.dart';
import '../studio_ui.dart';
import '../widgets.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static const _order = [
    Products.removeAds,
    Products.premium,
    Products.starterPack,
    Products.coinsSmall,
    Products.coinsLarge,
    Products.hintPack,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final ps = app.purchases;
    final prices = {for (final p in ps.products) p.id: p.price};
    final disabled = app.session.emergency.purchasesDisabled;
    return StudioScaffold(
      title: app.t('shop'),
      art: const StudioCrown(width: 28),
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.fromLTRB(4, 4, 4, 24), children: [
          CurrencyBar(app: app),
          if (!ps.available || disabled)
            StudioPanel(
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(child: Text(app.t('store_unavailable'), style: const TextStyle(color: Colors.white70))),
              ]),
            ),
          for (final id in _order)
            if (!(id == Products.starterPack && app.save.starterBought))
              StudioPanel(
                gradient: id == Products.premium
                    ? LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [const Color(0xFF6B3FA0).withValues(alpha: 0.85), const Color(0xFF2A1450).withValues(alpha: 0.85)])
                    : null,
                borderColor: id == Products.premium ? StudioLook.gold : null,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StudioIconBadge(_icon(id), color: _tint(id), size: 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.t(id), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      if (id == Products.removeAds)
                        Text(app.t('remove_ads_desc'), style: const TextStyle(color: Color(0xFFD9DCF0), fontSize: 13))
                      else ...[
                        if (id == Products.premium)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(app.t('premium_desc'),
                                style: const TextStyle(color: Color(0xFFD9DCF0), fontSize: 13)),
                          ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: RewardChips(reward: Products.grantFor(id)),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: app.save.ownedProducts.contains(id) && Products.nonConsumable.contains(id)
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: StudioLook.good.withValues(alpha: 0.18),
                                  border: Border.all(color: StudioLook.good),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.check_rounded, color: StudioLook.good, size: 18),
                                  const SizedBox(width: 4),
                                  Text(app.t('owned'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                ]),
                              )
                            : StudioButton(
                                expand: false,
                                height: 46,
                                fontSize: 16,
                                tone: id == Products.premium ? StudioButtonTone.gold : StudioButtonTone.play,
                                label: prices[id] ?? app.t('buy'),
                                onPressed: ps.available && !disabled && prices.containsKey(id)
                                    ? () async {
                                        if (await parentalGate(context, app)) ps.buy(id);
                                      }
                                    : null,
                              ),
                      ),
                    ]),
                  ),
                ]),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: StudioButton(
              tone: StudioButtonTone.ghost,
              icon: Icons.restore_rounded,
              label: app.t('restore_purchases'),
              onPressed: ps.available
                  ? () async {
                      if (await parentalGate(context, app)) ps.restore();
                    }
                  : null,
            ),
          ),
        ]),
      ),
    );
  }

  Color _tint(String id) => switch (id) {
        Products.removeAds => const Color(0xFFE0533D),
        Products.premium => const Color(0xFFD9A21C),
        Products.starterPack => const Color(0xFF7B4FD6),
        Products.hintPack => const Color(0xFFFF8A1F),
        _ => const Color(0xFF2F7BD9),
      };

  IconData _icon(String id) => switch (id) {
        Products.removeAds => Icons.block_rounded,
        Products.premium => Icons.workspace_premium_rounded,
        Products.starterPack => Icons.rocket_launch_rounded,
        Products.hintPack => Icons.lightbulb_rounded,
        _ => Icons.monetization_on_rounded,
      };
}
