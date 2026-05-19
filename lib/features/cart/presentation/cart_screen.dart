import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(localRepoProvider);
    final items = repo.getCart();
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
                      final price = double.tryParse('${p['price'] ?? 0}') ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text('${p['title'] ?? ''}'),
                          subtitle: Text('Кол-во: $qty • ${price.toStringAsFixed(2)} ${p['currency'] ?? 'USD'}'),
                          trailing: Text((price * qty).toStringAsFixed(2)),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Итого: ${total.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Перед подтверждением заказа менеджер проверит совместимость детали по VIN/OEM.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await _checkout(items, total, ref);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Спасибо за заказ! Мы скоро свяжемся с вами.' : 'Спасибо за заказ! Сохранили локально, отправка в Telegram не удалась.')));
                          }
                        },
                        child: const Text('Оформить заказ'),
                      ),
                    )
                  ]),
                )
              ],
            ),
    );
  }

  Future<bool> _checkout(List<Map<String, dynamic>> items, double total, WidgetRef ref) async {
    try {
      final payload = {
        'source': 'mobile_app',
        'total': total,
        'items': items,
      };
      await Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8080')).post('/api/orders/telegram', data: payload);
      await ref.read(localRepoProvider).saveOrder(OrderHistoryItem(
            id: 'ord_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
            createdAt: DateTime.now(),
            total: total,
            currency: 'USD',
            itemsCount: items.length,
            status: 'отправлен',
          ));
      await ref.read(localRepoProvider).clearCart();
      return true;
    } catch (_) {
      return false;
    }
  }
}
