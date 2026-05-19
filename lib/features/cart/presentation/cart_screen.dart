import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.read(localRepoProvider).getCart();
    final total = items.fold<double>(0, (sum, e) {
      final p = e['part'] as Map<dynamic, dynamic>?;
      final price = double.tryParse('${p?['price'] ?? 0}') ?? 0;
      final qty = e['quantity'] as int? ?? 1;
      return sum + price * qty;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: items.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i]['part'] as Map<dynamic, dynamic>;
                      final qty = items[i]['quantity'] as int? ?? 1;
                      return Card(child: ListTile(title: Text('${p['title'] ?? ''}'), subtitle: Text('Кол-во: $qty'), trailing: Text('${p['price'] ?? '0'} ${p['currency'] ?? ''}')));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Итого: ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Перед подтверждением заказа менеджер проверит совместимость детали по VIN/OEM.'),
                  ]),
                )
              ],
            ),
    );
  }
}
