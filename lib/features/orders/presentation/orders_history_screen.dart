import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';

class OrdersHistoryScreen extends ConsumerWidget {
  const OrdersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(localRepoProvider).getOrders()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: const Text('История заказов')),
      body: orders.isEmpty
          ? const Center(child: Text('История заказов пуста'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    title: Text('Заказ #${o.id.substring(o.id.length - 6)}'),
                    subtitle: Text('${DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt)} • ${o.itemsCount} поз.'),
                    trailing: Text('${o.total.toStringAsFixed(2)} ${o.currency}'),
                  ),
                );
              },
            ),
    );
  }
}
