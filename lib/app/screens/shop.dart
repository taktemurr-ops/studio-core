import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/monetization.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../parental_gate.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(app.t('shop'))),
      body: ContentWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        CurrencyBar(app: app),
        if (!ps.available || disabled)
          Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(app.t('store_unavailable')))),
        for (final id in _order)
          Card(
            child: ListTile(
              leading: Icon(_icon(id), color: Theme.of(context).colorScheme.primary),
              title: Text(app.t(id)),
              subtitle: RewardChips(reward: Products.grantFor(id)),
              trailing: app.save.ownedProducts.contains(id) && Products.nonConsumable.contains(id)
                  ? Text(app.t('owned'))
                  : FilledButton(
                      onPressed: ps.available && !disabled && prices.containsKey(id)
                          ? () async {
                              if (await parentalGate(context, app)) ps.buy(id);
                            }
                          : null,
                      child: Text(prices[id] ?? app.t('buy')),
                    ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.restore),
          label: Text(app.t('restore_purchases')),
          onPressed: ps.available
              ? () async {
                  if (await parentalGate(context, app)) ps.restore();
                }
              : null,
        ),
      ])),
    );
  }

  IconData _icon(String id) => switch (id) {
        Products.removeAds => Icons.block,
        Products.premium => Icons.workspace_premium,
        Products.starterPack => Icons.rocket_launch,
        Products.hintPack => Icons.lightbulb,
        _ => Icons.monetization_on,
      };
}
