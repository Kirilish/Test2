import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../garage/presentation/garage_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    final active = ref.watch(activeCarProvider);
    final services = ref.watch(servicesProvider);
    if (cars.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zapshop Garage')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.directions_car, size: 42),
                SizedBox(height: 8),
                Text('Добавьте автомобиль, чтобы видеть запчасти, напоминания и историю обслуживания'),
              ]),
            ),
          ),
        ),
      );
    }
    final car = cars.firstWhere((e) => e.id == active, orElse: () => cars.first);
    final list = services.where((e) => e.carId == car.id).toList();
    final total = list.fold<double>(0, (p, e) => p + e.price);
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_car)),
              title: Text(car.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Пробег: ${car.mileage} км • VIN: ${car.vin.isEmpty ? '-' : car.vin}'),
            ),
          ),
          Row(
            children: [
              Expanded(child: _metricCard('Расходы', '${total.toStringAsFixed(2)} USD', Icons.payments_outlined)),
              Expanded(child: _metricCard('Обслуживаний', '${list.length}', Icons.build_circle_outlined)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Быстрые действия', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _QuickAction(label: 'Подобрать запчасть', icon: Icons.search),
              _QuickAction(label: 'Открыть маркет', icon: Icons.storefront),
              _QuickAction(label: 'Добавить ремонт', icon: Icons.build),
              _QuickAction(label: 'Спросить AI', icon: Icons.smart_toy),
            ],
          )
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [Icon(icon), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))]))]),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скоро: $label'))),
    );
  }
}
