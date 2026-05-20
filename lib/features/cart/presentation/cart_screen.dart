import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models.dart';
import '../../../core/providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
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
                      final partId = int.tryParse('${p['id'] ?? 0}') ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text('${p['title'] ?? ''}'),
                          subtitle: Text('Кол-во: $qty • ${price.toStringAsFixed(2)} ${p['currency'] ?? 'USD'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((price * qty).toStringAsFixed(2)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await repo.removeFromCart(partId);
                                  if (mounted) setState(() {});
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено из корзины')));
                                },
                              )
                            ],
                          ),
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
                        onPressed: _submitting
                            ? null
                            : () async {
                                setState(() => _submitting = true);
                                final sentToTelegram = await _checkout(items, total);
                                if (!mounted) return;
                                setState(() => _submitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sentToTelegram ? 'Спасибо за заказ! Мы скоро свяжемся с вами.' : 'Спасибо за заказ! Заказ сохранен, Telegram временно недоступен.')));
                                context.push('/orders');
                              },
                        child: _submitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Оформить заказ'),
                      ),
                    )
                  ]),
                )
              ],
            ),
    );
  }

  Future<bool> _checkout(List<Map<String, dynamic>> items, double total) async {
    final payload = {'source': 'mobile_app', 'total': total, 'items': items};
    bool sent = false;
    try {
      await Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8080', connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8))).post('/api/orders/telegram', data: payload);
      sent = true;
    } catch (_) {
      sent = false;
    }

    await ref.read(localRepoProvider).saveOrder(OrderHistoryItem(
          id: 'ord_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
          createdAt: DateTime.now(),
          total: total,
          currency: 'USD',
          itemsCount: items.length,
          status: sent ? 'отправлен' : 'сохранен локально',
        ));
    await ref.read(localRepoProvider).clearCart();
    return sent;
  }
}
