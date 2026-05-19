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
      return Scaffold(appBar: AppBar(title: const Text('Zapshop Garage')), body: const Center(child: Text('Добавьте автомобиль, чтобы видеть запчасти, напоминания и историю обслуживания')));
    }
    final car = cars.firstWhere((e) => e.id == active, orElse: () => cars.first);
    final list = services.where((e) => e.carId == car.id).toList();
    final total = list.fold<double>(0, (p, e) => p + e.price);
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: ListTile(title: Text(car.title), subtitle: Text('Пробег: ${car.mileage} км'))),
        Card(child: ListTile(title: const Text('Расходы по авто'), subtitle: Text(total.toStringAsFixed(2)))),
        Card(child: ListTile(title: const Text('Записей обслуживания'), subtitle: Text('${list.length}'))),
      ]),
    );
  }
}
