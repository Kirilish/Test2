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
                final statusColor = o.status.contains('локально') ? Colors.orange : Colors.green;
                return Card(
                  child: ListTile(
                    title: Text('Заказ #${o.id.substring(o.id.length - 6)}'),
                    subtitle: Text('${DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt)} • ${o.itemsCount} поз.'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${o.total.toStringAsFixed(2)} ${o.currency}'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text(o.status, style: TextStyle(color: statusColor, fontSize: 11)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
